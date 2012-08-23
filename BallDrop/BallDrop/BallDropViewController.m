//
//  BallDropViewController.m
//  BallDrop
//
//  Created by Kristina Fedorenko on 8/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BallDropViewController.h"
#import "BallDropStartUpViewController.h"
#import "BallDropModel.h"

#define NUM_BALL_SECTIONS 32
#define BALL_RADIUS 10
#define BLOCK_RADIUS 6
#define SOURCE_SIZE 25

@interface BallDropViewController ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) BallDropModel *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (nonatomic) GLKMatrix4 viewModelMatrix; //how everything should be rendered normally
@property (strong, nonatomic) UIPopoverController *startUpPopover;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) id selectedItem;



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
@synthesize viewModelMatrix = _viewModelMatrix;
@synthesize startUpPopover = _startUpPopover;

/* 
 Getter for the model with lazy instantiation
*/
- (BallDropModel *)model
{
    if (!_model){
        _model = [[BallDropModel alloc] init];
    }
    return _model;
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
    
    //gestures:
    UITapGestureRecognizer *tap =[[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(handleTap:)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan =[[UIPanGestureRecognizer alloc] initWithTarget: self action:@selector(handlePan:)];
    pan.delegate = self;
    [self.view addGestureRecognizer:pan];
    
    
    [self setupGL];
}


- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    self.effect = [[GLKBaseEffect alloc] init];
    
    int width = self.view.bounds.size.width;
    int height = self.view.bounds.size.height;

    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, width, height, 0, 0.0, 1.0); //invert y-axis to match screen coords
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    //self.viewModelMatrix = GLKMatrix4Translate(GLKMatrix4Identity, self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0);//origin at the center of the screen
    
    self.viewModelMatrix = GLKMatrix4Identity;

    self.effect.transform.modelviewMatrix = self.viewModelMatrix;
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

- (void) renderModel
{
    int i;
    for (i = 0; i < self.model.balls.count; i++){
        BallDropBall ball;
        [[self.model.balls objectAtIndex:i] getValue:&ball];
        [self renderBall:ball];
    }
    for (i = 0; i < self.model.blocks.count; i++){
        BallDropBlock block;
        [[self.model.blocks objectAtIndex:i] getValue:&block];
        [self renderBlock:block];
    }
    for (i = 0; i < self.model.ballSources.count; i++){
        BallDropBallSource source;
        [[self.model.ballSources objectAtIndex:i] getValue:&source];
        [self renderBallSource:source];
    }
}

- (void) renderBall: (BallDropBall) ball
{
    
    //tranforms to draw current ball:
    GLKMatrix4 ballModelMatrix = GLKMatrix4Translate(self.viewModelMatrix, ball.center.x, ball.center.y, 0);
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
    self.effect.transform.modelviewMatrix = self.viewModelMatrix; 
    [self.effect prepareToDraw];
}

- (void) renderBlock: (BallDropBlock) block
{
    
    //get color VBOs
    GLuint circleVBO = [self getBallVBOofColor:block.Color];
    GLuint rectVBO = [self getRectVBOofColor:block.Color];
    
    
    // block start
    GLKMatrix4 blockModelMatrix = GLKMatrix4Translate(self.viewModelMatrix, block.p1.x, block.p1.y, 0);
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
    blockModelMatrix = GLKMatrix4Translate(self.viewModelMatrix, block.p2.x, block.p2.y, 0);
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
    float dx = block.p2.x - block.p1.x;
    float dy = block.p2.y - block.p1.y;
    //translate to block center
    blockModelMatrix = GLKMatrix4Translate(self.viewModelMatrix, block.p1.x + dx/2, block.p1.y + dy/2, 0);
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
    self.effect.transform.modelviewMatrix = self.viewModelMatrix; 
    [self.effect prepareToDraw];
    
}

- (void) renderBallSource: (BallDropBallSource) source
{
    float defaultSourceColor[4] = {0, 0, 0, 1};
    GLuint rectVBO = [self getRectVBOofColor: defaultSourceColor];
    
    //tranforms to draw current source:
    GLKMatrix4 sourceModelMatrix = GLKMatrix4Translate(self.viewModelMatrix, source.xpos - SOURCE_SIZE/2, SOURCE_SIZE/2, 0);
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
    self.effect.transform.modelviewMatrix = self.viewModelMatrix; 
    [self.effect prepareToDraw];
    
}


- (void) handleTap:(UITapGestureRecognizer *) tap
{
    
}

/*
 Adds a new block
*/
- (void) handlePan:(UIPanGestureRecognizer *) pan
{
    CGPoint location = [pan locationInView:self.view];
 
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

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *) touch 
{
    return ([touch locationInView:self.view].y < self.view.bounds.size.height - 70);
}


- (IBAction)newFilePressed:(UIButton *)sender 
{
    NSLog(@"new file");
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
}

- (IBAction)playStopPressed:(UIButton *)sender {
    self.isPlaying = !self.isPlaying;
    
    if (self.isPlaying) {
        [sender setTitle:@"□" forState:UIControlStateNormal];
    }
    else {
        [sender setTitle:@"▷" forState:UIControlStateNormal];
    }
}

- (IBAction)helpPressed:(UIButton *)sender 
{
    if (!self.startUpPopover){
        BallDropStartUpViewController *content = [[BallDropStartUpViewController alloc] init];
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:content];
        popover.delegate = self;
    
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
    return YES;
}

//- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
//{
//    glClearColor(0.65f, 0.68f, 0.77f, 1.0f);
//    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//    
//    //[self.effect prepareToDraw];
//    //[self renderModel];        
//}


#pragma mark - GLKView and GLKViewController delegate methods

//- (void)update
//{
//    
//}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
    [self renderModel];
}



@end
