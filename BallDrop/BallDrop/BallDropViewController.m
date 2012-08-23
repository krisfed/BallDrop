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
#import "BallDropSound.h"

#define NUM_BALL_SEGMENTS	32

@interface BallDropViewController ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) BallDropModel *model;
@property (strong, nonatomic) UIPopoverController *startUpPopover;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) id selectedItem;


@end

@implementation BallDropViewController

@synthesize model = _model;
@synthesize isPlaying = _isPlaying;
@synthesize selectedItem = _selectedItem;
@synthesize context = _context;
@synthesize startUpPopover = _startUpPopover;

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
    
    UITapGestureRecognizer *tap =[[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(handleTap:)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan =[[UIPanGestureRecognizer alloc] initWithTarget: self action:@selector(handlePan:)];
    pan.delegate = self;
    [self.view addGestureRecognizer:pan];
}

- (void) renderModel
{
    int i;
    for (i = 0; i < self.model.balls.count; i++){
        BallDropBall ball;
        [[self.model.balls objectAtIndex:i] getValue:&ball];
        [self renderBall:&ball];
    }
    for (i = 0; i < self.model.blocks.count; i++){
        BallDropBlock block;
        [[self.model.blocks objectAtIndex:i] getValue:&block];
        [self renderBlock:&block];
    }
    for (i = 0; i < self.model.ballSources.count; i++){
        BallDropBallSource source;
        [[self.model.ballSources objectAtIndex:i] getValue:&source];
        [self renderBallSource:&source];
    }
}

- (void) renderBall: (BallDropBall *) ball
{
    
}

- (void) renderBlock: (BallDropBlock *) block
{
    
}

- (void) renderBallSource: (BallDropBallSource *) source
{
    
}


- (void) handleTap:(UITapGestureRecognizer *) tap
{
    NSLog(@"Tap!");
}

- (void) handlePan:(UIPanGestureRecognizer *) pan
{
    NSLog(@"Pan Recognized");
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *) touch 
{
    return ([touch locationInView:self.view].y < self.view.bounds.size.height - 70);
}


- (IBAction)newFilePressed:(UIButton *)sender 
{
    [BallDropSound makeSoundofType:1 ofNote:0];
}

- (IBAction)saveFilePressed:(UIButton *)sender 
{
    [BallDropSound makeSoundofType:1 ofNote:2];
}

- (IBAction)loadFilePressed:(UIButton *)sender 
{
    [BallDropSound makeSoundofType:1 ofNote:5];
}

- (IBAction)helpPressed:(UIButton *)sender 
{
    [BallDropSound makeSoundofType:1 ofNote:7];
    if (!self.startUpPopover){
        BallDropStartUpViewController *content = [[BallDropStartUpViewController alloc] init];
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:content];
        popover.delegate = self;
        
        self.startUpPopover = popover;
    }
    
    
    [self.startUpPopover presentPopoverFromRect:CGRectMake(self.view.bounds.size.width/2,400, 1, 1) inView:self.view permittedArrowDirections:0 animated:YES];
}

- (IBAction)newBallSourcePressed:(UIButton *)sender 
{
    [BallDropSound makeSoundofType:1 ofNote:10];
}

- (IBAction)playStopPressed:(UIButton *)sender {
    [BallDropSound makeSoundofType:1 ofNote:12];
    self.isPlaying = !self.isPlaying;
    
    if (self.isPlaying) {
        [sender setTitle:@"□" forState:UIControlStateNormal];
    }
    else {
        [sender setTitle:@"▷" forState:UIControlStateNormal];
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.65f, 0.68f, 0.77f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //[self.effect prepareToDraw];
    //[self renderModel];        
}

@end
