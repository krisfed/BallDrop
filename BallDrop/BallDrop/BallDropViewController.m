//
//  BallDropViewController.m
//  BallDrop
//
//  Created by Kristina Fedorenko on 8/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BallDropViewController.h"
#import "BallDropStartUpViewController.h"
#import "BallDropEditBlockViewController.h"
#import "BallDropEditBallSourceViewController.h"
#import "BallDropModel.h"
#import "BallDropPhysics.h"

#define NUM_BALL_SECTIONS 32
#define MAX_NUM_BALLS 10
#define SOURCE_SIZE 25
#define HANDLES_SIZE 20
#define SELECTION_RADIUS 10 //how sensitive selection is to touch

@interface BallDropViewController ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) BallDropModel *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (strong, nonatomic) UIPopoverController *startUpPopover;
@property (strong, nonatomic) UIPopoverController *blockEditPopover;
@property (strong, nonatomic) UIPopoverController *sourceEditPopover;
@property (strong, nonatomic) id selectedItem; //pointer to currently selected object
@property (nonatomic) enum EditObjectState editObjectState; //if a block is currently being edited, and in what way
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) int beatCounter;
@property (nonatomic) int updateCounter;



@end

@interface BallDropViewController()
{
    Vertex _circleVertices[NUM_BALL_SECTIONS + 2];
    Vertex _rectVertices[4];
}
@end

@implementation BallDropViewController

@synthesize model = _model;
@synthesize isPlaying = _isPlaying;
@synthesize selectedItem = _selectedItem;
@synthesize context = _context;
@synthesize effect = _effect;
@synthesize startUpPopover = _startUpPopover;
@synthesize blockEditPopover = _blockEditPopover;
@synthesize sourceEditPopover = _sourceEditPopover;
@synthesize beatCounter = _beatCounter;
@synthesize updateCounter = _updateCounter;
@synthesize editObjectState = _editBlockState;

/* 
 Getter for the model with lazy instantiation
*/
- (BallDropModel *)model
{
    if (!_model){
        
        BDHalfPlane rightPlane;
        BDHalfPlane leftPlane;
        BDHalfPlane topPlane;
        
        rightPlane.pointOnPlane[0] = self.view.bounds.size.width;
        rightPlane.pointOnPlane[1] = 0;
        leftPlane.pointOnPlane[0] = 0;
        leftPlane.pointOnPlane[1] = 0;
        topPlane.pointOnPlane[0] = 0;
        topPlane.pointOnPlane[1] = self.view.bounds.size.height;
        
        rightPlane.outwardUnitNormal[0] = -1;
        rightPlane.outwardUnitNormal[1] = 0;
        leftPlane.outwardUnitNormal[0] = 1;
        leftPlane.outwardUnitNormal[1] = 0;
        topPlane.outwardUnitNormal[0] = 0;
        topPlane.outwardUnitNormal[1] = -1;
        
        _model = [[BallDropModel alloc] initWithHalfPlanesRight:rightPlane Left:leftPlane Top:topPlane];
    }
    return _model;
}

/*
 Getter for the block edit popover with lazy instantiation
*/
- (UIPopoverController *)blockEditPopover
{
    if (!_blockEditPopover) {
        BallDropEditBlockViewController *content = [[BallDropEditBlockViewController alloc] init];
        self.blockEditPopover = [[UIPopoverController alloc] initWithContentViewController:content];
        self.blockEditPopover.delegate = self;
        
    }
    
    return _blockEditPopover;
}

/*
 Getter for the ball source edit popover with lazy instantiation
 */
- (UIPopoverController *)sourceEditPopover
{
    if (!_sourceEditPopover) {
        BallDropEditBallSourceViewController *content = [[BallDropEditBallSourceViewController alloc] init];
        self.sourceEditPopover = [[UIPopoverController alloc] initWithContentViewController:content];
        self.sourceEditPopover.delegate = self;
        
    }
    
    return _sourceEditPopover;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    
    // initialize vertex models for circle and rectangle
    [self makeVertexModels];
    
    //no block is being edited at the start
    self.editObjectState = EDIT_NO_OBJECT;
    
    //gestures:
    UITapGestureRecognizer *tap =[[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(handleTap:)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan =[[UIPanGestureRecognizer alloc] initWithTarget: self action:@selector(handlePan:)];
    pan.delegate = self;
    [self.view addGestureRecognizer:pan];
    
    self.preferredFramesPerSecond = 30;
    
    [self setupGL];
    self.view.contentMode = UIViewContentModeRedraw;

}


- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    self.effect = [[GLKBaseEffect alloc] init];
    
    int width = self.view.bounds.size.width;
    int height = self.view.bounds.size.height;

    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, width, 0, height, 0.0, 1.0); //invert y-axis to match screen coords
    self.effect.transform.projectionMatrix = projectionMatrix;

    [self.effect prepareToDraw];
    
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    self.effect = nil;
}


/*
 Create vertices of a white circle at 0,0 with radius of 1
 and of a white square rectangle at 0,0 with a side of 1
 to put into instance variable for future use
 */
- (void) makeVertexModels
{
    
    // make circle vertices
    Vertex center = {{0, 0}, {1, 1, 1, 1}};  
    _circleVertices[0] = center;
    for (int i =0; i<=NUM_BALL_SECTIONS; i++) {
        Vertex curcumfPoint = {
            //position: (x, y)
            {cos(i * 2 * M_PI / NUM_BALL_SECTIONS), sin(i * 2 * M_PI / NUM_BALL_SECTIONS)},
            //color: (r, g, b, a)
            {1, 1, 1, 1}
        };
        _circleVertices[i+1] = curcumfPoint;
    }
    
    // make rect vertices
    Vertex vertex0 = {{-0.5, -0.5}, {1, 1, 1, 1}};
    Vertex vertex1 = {{0.5, -0.5}, {1, 1, 1, 1}};
    Vertex vertex2 = {{-0.5, 0.5}, {1, 1, 1, 1}}; 
    Vertex vertex3 = {{0.5, 0.5}, {1, 1, 1, 1}};
    
    _rectVertices[0] = vertex0;
    _rectVertices[1] = vertex1;
    _rectVertices[2] = vertex2;
    _rectVertices[3] = vertex3;
    
    
}


/* 
 Using instance variable containing vetex model of a circle,
 return Vertex Buffer Object for a circle of a specified color
 */
- (GLuint)getBallVBOofColor:(float[4]) color
{
    GLuint vertexBuffer;
    
    // change color
    for (int i = 0; i<sizeof(_circleVertices)/sizeof(Vertex); i++) {
        _circleVertices[i].Color[0] = color[0];
        _circleVertices[i].Color[1] = color[1];
        _circleVertices[i].Color[2] = color[2];
        _circleVertices[i].Color[3] = color[3];
    }
    
    
    // create a VBO out of the vertices
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_circleVertices), _circleVertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    return vertexBuffer;
}

/* 
 Using instance variable containing vetex model for a rectangle,
 return Vertex Buffer Object for a rectangle of a specified color
 */
- (GLuint)getRectVBOofColor: (float[4]) color
{
    GLuint vertexBuffer;
    
    // change color
    for (int i = 0; i<sizeof(_rectVertices)/sizeof(Vertex); i++) {
        _rectVertices[i].Color[0] = color[0];
        _rectVertices[i].Color[1] = color[1];
        _rectVertices[i].Color[2] = color[2];
        _rectVertices[i].Color[3] = color[3];
    }
    
    
    // create a VBO out of the vertices
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_rectVertices), _rectVertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    return vertexBuffer;
}

/*
 Renders the model by iterating through and rendering each
 element of the model
*/
- (void) renderModel
{
    int i;
    //----balls:
    for (i = 0; i < self.model.balls.count; i++){
        BDBall ball;
        [[self.model.balls objectAtIndex:i] getValue:&ball];
        [self renderBall:ball];
    }
    
    //----blocks:
    for (i = 0; i < self.model.blocks.count; i++){
        BDBlock block;
        id blockObject = [self.model.blocks objectAtIndex:i];
        [blockObject getValue:&block];
        
        if (blockObject == self.selectedItem) {
            [self renderSelectedBlock:block];
        } else {
            [self renderBlock:block];
        }
    }
    
    //----ball sources:
    for (i = 0; i < self.model.ballSources.count; i++){
        BDBallSource source;
        id sourceObject = [self.model.ballSources objectAtIndex:i];
        [sourceObject getValue:&source];
        
        if (sourceObject == self.selectedItem) {
            [self renderSelectedBallSource: source];
        } else {
            [self renderBallSource: source];
        }
        
    }
}

- (void) renderBall: (BDBall) ball
{
    
    //tranforms to draw current ball:
    GLKMatrix4 ballModelMatrix = GLKMatrix4Translate(GLKMatrix4Identity, ball.centerPoint[0], ball.centerPoint[1], 0);
    ballModelMatrix = GLKMatrix4Scale(ballModelMatrix, BALL_RADIUS, BALL_RADIUS, 1);
    self.effect.transform.modelviewMatrix = ballModelMatrix;
    [self.effect prepareToDraw];
    
    //draw:    
    GLuint VBO = [self getBallVBOofColor:ball.Color];
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), 
                          (const GLvoid *) offsetof(Vertex, Color));
    glDrawArrays(GL_TRIANGLE_FAN, 0, NUM_BALL_SECTIONS+2);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glDisableVertexAttribArray(GLKVertexAttribColor);
    
    //return to normal:
    self.effect.transform.modelviewMatrix = GLKMatrix4Identity; 
    [self.effect prepareToDraw];
}


- (void) renderBlock: (BDBlock) block
{
    
    //get color VBOs
    GLuint circleVBO = [self getBallVBOofColor:block.Color];
    GLuint rectVBO = [self getRectVBOofColor:block.Color];
    
    
    // block start
    GLKMatrix4 blockModelMatrix = GLKMatrix4Translate(GLKMatrix4Identity, block.startPoint[0], block.startPoint[1], 0);
    blockModelMatrix = GLKMatrix4Scale(blockModelMatrix, BLOCK_RADIUS, BLOCK_RADIUS, 1);
    self.effect.transform.modelviewMatrix = blockModelMatrix;
    [self.effect prepareToDraw];
    
    glBindBuffer(GL_ARRAY_BUFFER, circleVBO);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Color));
    glDrawArrays(GL_TRIANGLE_FAN, 0, NUM_BALL_SECTIONS+2);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    //line end
    blockModelMatrix = GLKMatrix4Translate(GLKMatrix4Identity, block.endPoint[0], block.endPoint[1], 0);
    blockModelMatrix = GLKMatrix4Scale(blockModelMatrix, BLOCK_RADIUS, BLOCK_RADIUS, 1);
    self.effect.transform.modelviewMatrix = blockModelMatrix;
    [self.effect prepareToDraw];
    
    glBindBuffer(GL_ARRAY_BUFFER, circleVBO);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Color));
    glDrawArrays(GL_TRIANGLE_FAN, 0, NUM_BALL_SECTIONS+2);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    
    //block body
    float dx = block.endPoint[0] - block.startPoint[0];
    float dy = block.endPoint[1] - block.startPoint[1];
    //translate to block center
    blockModelMatrix = GLKMatrix4Translate(GLKMatrix4Identity, block.startPoint[0] + dx/2, block.startPoint[1] + dy/2, 0);
    //rotate to block's angle
    blockModelMatrix = GLKMatrix4RotateZ(blockModelMatrix, atanf(dy/dx));
    //stretch to block size
    float blockLength = sqrtf( powf(dx, 2) + powf(dy, 2));
    blockModelMatrix = GLKMatrix4Scale(blockModelMatrix, blockLength, BLOCK_RADIUS*2, 1);
    
    //draw
    self.effect.transform.modelviewMatrix = blockModelMatrix;
    [self.effect prepareToDraw];
    
    glBindBuffer(GL_ARRAY_BUFFER, rectVBO);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Color));
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    //return to normal:
    self.effect.transform.modelviewMatrix = GLKMatrix4Identity;
    [self.effect prepareToDraw];
    
}


- (void) renderSelectedBlock: (BDBlock) block
{
    
    //get color VBOs
    float red[4] = {0.75, 0, 0, 1};
    GLuint circleVBO = [self getBallVBOofColor:red];
    GLuint rectVBO = [self getRectVBOofColor: block.Color]; 
    
    
    //block body
    float dx = block.endPoint[0] - block.startPoint[0];
    float dy = block.endPoint[1] - block.startPoint[1];
    //translate to block center
    GLKMatrix4 blockModelMatrix = GLKMatrix4Translate(GLKMatrix4Identity, block.startPoint[0] + dx/2, block.startPoint[1] + dy/2, 0);
    //rotate to block's angle
    blockModelMatrix = GLKMatrix4RotateZ(blockModelMatrix, atanf(dy/dx));
    //stretch to block size
    float blockLength = sqrtf( powf(dx, 2) + powf(dy, 2));
    blockModelMatrix = GLKMatrix4Scale(blockModelMatrix, blockLength, BLOCK_RADIUS*2, 1);
    
    //draw
    self.effect.transform.modelviewMatrix = blockModelMatrix;
    [self.effect prepareToDraw];
    
    glBindBuffer(GL_ARRAY_BUFFER, rectVBO);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Color));
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    //return to normal:
    self.effect.transform.modelviewMatrix = GLKMatrix4Identity;
    [self.effect prepareToDraw];
    
    
    // block start
    blockModelMatrix = GLKMatrix4Translate(GLKMatrix4Identity, block.startPoint[0], block.startPoint[1], 0);
    blockModelMatrix = GLKMatrix4Scale(blockModelMatrix, HANDLES_SIZE, HANDLES_SIZE, 1);
    self.effect.transform.modelviewMatrix = blockModelMatrix;
    [self.effect prepareToDraw];
    
    glBindBuffer(GL_ARRAY_BUFFER, circleVBO);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Color));
    glDrawArrays(GL_TRIANGLE_FAN, 0, NUM_BALL_SECTIONS+2);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    //return to normal:
    self.effect.transform.modelviewMatrix = GLKMatrix4Identity;
    [self.effect prepareToDraw];
    
    //block end
    blockModelMatrix = GLKMatrix4Translate(GLKMatrix4Identity, block.endPoint[0], block.endPoint[1], 0);
    blockModelMatrix = GLKMatrix4Scale(blockModelMatrix, HANDLES_SIZE, HANDLES_SIZE, 1);
    self.effect.transform.modelviewMatrix = blockModelMatrix;
    [self.effect prepareToDraw];
    
    glBindBuffer(GL_ARRAY_BUFFER, circleVBO);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Color));
    glDrawArrays(GL_TRIANGLE_FAN, 0, NUM_BALL_SECTIONS+2);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    //return to normal:
    self.effect.transform.modelviewMatrix = GLKMatrix4Identity;
    [self.effect prepareToDraw];
        
}


- (void) renderBallSource: (BDBallSource) source
{
    float defaultSourceColor[4] = {0, 0, 0, 1};
    GLuint rectVBO = [self getRectVBOofColor: defaultSourceColor];
    
    //tranforms to draw current source:
    GLKMatrix4 sourceModelMatrix = GLKMatrix4Translate(GLKMatrix4Identity, source.xpos, self.view.bounds.size.height - SOURCE_SIZE/2, 0);
    sourceModelMatrix = GLKMatrix4Scale(sourceModelMatrix, SOURCE_SIZE, SOURCE_SIZE, 1);
    self.effect.transform.modelviewMatrix = sourceModelMatrix;
    [self.effect prepareToDraw];
    
    //draw
    glBindBuffer(GL_ARRAY_BUFFER, rectVBO);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), 
                          (const GLvoid *) offsetof(Vertex, Color));
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    //return to normal:
    self.effect.transform.modelviewMatrix = GLKMatrix4Identity; 
    [self.effect prepareToDraw];
    
}

- (void) renderSelectedBallSource: (BDBallSource) source
{
    //translate to the position of current source
    GLKMatrix4 sourceModelMatrix = GLKMatrix4Translate(GLKMatrix4Identity, source.xpos, self.view.bounds.size.height - SOURCE_SIZE/2, 0);
    
    // ==== draw outline:
    float outlineColor[4] = {0.75, 0, 0, 1};
    GLuint rectVBO = [self getRectVBOofColor: outlineColor];
    
    //scale to outline size:
    self.effect.transform.modelviewMatrix = GLKMatrix4Scale(sourceModelMatrix, SOURCE_SIZE+15, SOURCE_SIZE+15, 1);
    [self.effect prepareToDraw];
    
    //draw outline
    glBindBuffer(GL_ARRAY_BUFFER, rectVBO);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), 
                          (const GLvoid *) offsetof(Vertex, Color));
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    // ==== draw source:
    float defaultSourceColor[4] = {0, 0, 0, 1};
    rectVBO = [self getRectVBOofColor: defaultSourceColor];
    
    //scale to source size:
    self.effect.transform.modelviewMatrix = GLKMatrix4Scale(sourceModelMatrix, SOURCE_SIZE, SOURCE_SIZE, 1);
    [self.effect prepareToDraw];
    
    //draw
    glBindBuffer(GL_ARRAY_BUFFER, rectVBO);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), 
                          (const GLvoid *) offsetof(Vertex, Color));
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    
    

    
    //return to normal:
    self.effect.transform.modelviewMatrix = GLKMatrix4Identity; 
    [self.effect prepareToDraw];
    
}


/* 
 If the game is stopped, selects/unselects blocks and ball sources
 */
- (void) handleTap:(UITapGestureRecognizer *) tap
{    
    if (!self.isPlaying) {
        CGPoint location = [tap locationInView:self.view];
        //location.y = self.view.bounds.size.height - location.y;
        float touch[2] = {location.x, self.view.bounds.size.height - location.y};
        
        //preference in selection is given to blocks:
        self.selectedItem = [self blockAtPoint: touch];
        //if there is block selected, show block edit popover:
        if (self.selectedItem) {
            [self.blockEditPopover presentPopoverFromRect:CGRectMake(location.x, location.y, 10, 10) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        //if no block selected, check for sources    
        } else {
            self.selectedItem = [self ballSourceAtPoint:touch];
            
            //if source is selected, show source edit popover
            if (self.selectedItem) {
                [self.sourceEditPopover presentPopoverFromRect:CGRectMake(location.x, location.y, 10, 10) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        }
        

    }
}


/*
 Pan gesture: 
 if there is an object selected, allows to edit it
 otherwise, adds a new block
*/
- (void) handlePan:(UIPanGestureRecognizer *) pan
{
   
        CGPoint location = [pan locationInView:self.view];
        location.y = self.view.bounds.size.height - location.y;
    
        //==== if there is an object currently selected
        if (self.selectedItem) {
            float touch[2] = {location.x, location.y};
            
            //==== if it is a first touch of the pan gesture
            if (pan.state == UIGestureRecognizerStateBegan) {                                
                //==== if touched the selected block:
                if ([self blockAtPoint:touch] == self.selectedItem) {
                    BDBlock selectedBlock;
                    [self.selectedItem getValue:&selectedBlock];
                    //==== if touched the start point handle:
                    if (bdGetDistanceBetweenPoints(touch, selectedBlock.startPoint) <= HANDLES_SIZE) {
                        self.editObjectState = EDIT_START_HANDLE;
                    //==== if touched the end point handle:    
                    } else if (bdGetDistanceBetweenPoints(touch, selectedBlock.endPoint) <= HANDLES_SIZE) {
                        self.editObjectState = EDIT_END_HANDLE;
                    //==== if touched the body of the block    
                    } else {
                        self.editObjectState = EDIT_BLOCK_POSITION;
                    }
                //==== if touched the selected ball source:
                } else if ([self ballSourceAtPoint: touch] == self.selectedItem) {
                    self.editObjectState = EDIT_SOURCE_POSITION;
                }
                
                
            //==== if it is the continuation of pan gesture    
            } else if (pan.state == UIGestureRecognizerStateChanged){
                switch (self.editObjectState) {
                    case EDIT_START_HANDLE:
                        self.selectedItem = [self.model updateBlock:self.selectedItem withStartpoint:touch];
                        break;
                    case EDIT_END_HANDLE:
                        self.selectedItem = [self.model updateBlock:self.selectedItem withEndpoint:touch];
                        break;
                    case EDIT_BLOCK_POSITION:
                        self.selectedItem = [self.model moveBlock:self.selectedItem toPosition:touch];
                        break;
                    case EDIT_SOURCE_POSITION:
                        self.selectedItem = [self.model moveBallSource:self.selectedItem toPosition:touch[0]];
                    default:
                        break;
                }
            //==== if it is the end of pan gesture
            } else {
                self.editObjectState = EDIT_NO_OBJECT;
            }
            
            
        //==== if there is no object selected    
        } else {
            //create a new block
            if (pan.state == UIGestureRecognizerStateBegan)
            {
                [self.model startNewBlockFrom:location];
            }
            else if (pan.state == UIGestureRecognizerStateEnded)
            {
                [self.model finalizeNewBlockTo:location];
            }
            else if (pan.state == UIGestureRecognizerStateChanged)
            {
                [self.model updateNewBlockTo:location];
            }
        }
                
}



/*
 Returns a block that is at a specified point,
 nil if there is nothing
*/

-(id)blockAtPoint: (float[]) point
{
    
    for (int i = 4; i < self.model.blocks.count; i++) {//ignore first 4 blocks
        BDBlock block;
        [[self.model.blocks objectAtIndex:i] getValue: &block];
        float dist = bdGetDistanceToBlock(point, &block);
        if (dist<SELECTION_RADIUS) {
            return [self.model.blocks objectAtIndex:i];
        }
        
    }
    
    return nil;
    
}
    
/*
 Returns a ball source that is a at a specified point
 (if several, the closest one),
 nil if there is nothing
*/
- (id)ballSourceAtPoint: (float[]) point
{
    id selectedSource = nil;
    
    //selectable area is a circle large enough to contain the 
    //square of ball source:
    float minDist = SOURCE_SIZE * sqrt(2) + SELECTION_RADIUS;
    float ypos = self.view.bounds.size.height - SOURCE_SIZE/2;
    for (int i = 0; i< self.model.ballSources.count; i++) {
        BDBallSource source;
        [[self.model.ballSources objectAtIndex:i] getValue:&source];
        float position[2] = {source.xpos, ypos};
        if (bdGetDistanceBetweenPoints(position, point) < minDist) {
            selectedSource = [self.model.ballSources objectAtIndex:i];
        }
    }
    
    
    return selectedSource;
}
   


/*
 Prevents tap gesture from interfering with buttons by
 creating a non-tapable area for buttons (70 pixels from the
 bottom of the screen)
*/
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *) touch 
{
    return ([touch locationInView:self.view].y < self.view.bounds.size.height - 70);
}


// =========== Popover delegate methods ==========================
/*
 Parameters:
 popoverController
 The popover controller to be dismissed.
 
 Return Value:
 YES if the popover should be dismissed or NO if it should remain visible.
 
 This method is called in response to user-initiated attempts to dismiss the popover. It is not called when you dismiss the popover using the dismissPopoverAnimated: method of the popover controller.
 
 If you do not implement this method in your delegate, the default return value is assumed to be YES. 
 */

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return YES;
}


/*
 Parameters:
 popoverController
 The popover controller that was dismissed.
 
 The popover controller does not call this method in response to programmatic calls to the dismissPopoverAnimated: method. If you dismiss the popover programmatically, you should perform any cleanup actions immediately after calling the dismissPopoverAnimated: method.
 
 You can use this method to incorporate any changes from the popover’s content view controller back into your application. If you do not plan to use the object in the popoverController parameter again, it is safe to release it from this method. 
 */
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    NSLog(@"Popover was dismissed!");
    
    self.blockEditPopover = nil;
    self.sourceEditPopover = nil;
}
// =========== Popover delegate methods ==========================


- (IBAction)newFilePressed:(UIButton *)sender 
{
    NSLog(@"new file");
    if (!self.isPlaying)
    {
        self.model = nil;
        self.selectedItem = nil;
        self.editObjectState = EDIT_NO_OBJECT;
        
    }
}

- (IBAction)saveFilePressed:(UIButton *)sender 
{
    NSLog(@"save file");
}

- (IBAction)loadFilePressed:(UIButton *)sender 
{
    NSLog(@"load file");
}

- (IBAction)newBallSourcePressed:(UIButton *)sender 
{
    NSLog(@"new ball source");
    int randomX = arc4random() % (int)self.view.bounds.size.width;
    [self.model addBallSourceAt:randomX];
}

- (IBAction)playStopPressed:(UIButton *)sender {
    self.isPlaying = !self.isPlaying;
    
    if (self.isPlaying) {
        [sender setTitle:@"□" forState:UIControlStateNormal];
        self.model.balls = [[NSMutableArray alloc] init];
    }
    else {
        [sender setTitle:@"▷" forState:UIControlStateNormal];
        self.beatCounter = 0;
        self.updateCounter = 0;
        self.model.balls = [[NSMutableArray alloc] init];
    }
}

/*
 Displays a popover with instructions
*/
- (IBAction)helpPressed:(UIButton *)sender 
{
    if (!self.startUpPopover){
        BallDropStartUpViewController *content = [[BallDropStartUpViewController alloc] init];
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:content];
        //popover.delegate = self;
    
        self.startUpPopover = popover;
    }
    
    
    [self.startUpPopover presentPopoverFromRect:CGRectMake(self.view.bounds.size.width/2,400, 1, 1) inView:self.view permittedArrowDirections:0 animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait) || 
    (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    if (self.isPlaying)
    {
        self.selectedItem = nil;
        
        int i;
        if (self.updateCounter >= 15){
            self.updateCounter = 0;
        }
        if (self.updateCounter == 0) {
            for (i = 0; i < self.model.ballSources.count; i++){
                BDBallSource source;
                [[self.model.ballSources objectAtIndex:i] getValue:&source];
                if ((self.model.balls.count < MAX_NUM_BALLS)
                    &&((self.beatCounter % source.period) == 0)){
                    [self.model addBallAt:CGPointMake(source.xpos, self.view.bounds.size.height)];
                }
            }   
            self.beatCounter++;
        }
        
        [self.model advanceModelState:0.033];
    }    
    self.updateCounter++;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
    [self renderModel];
}



@end
