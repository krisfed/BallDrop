//
//  BallDropViewController.m
//  BallDrop
//
//  Created by Kristina Fedorenko on 8/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BallDropViewController.h"
#import "BallDropModel.h"

@interface BallDropViewController ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) BallDropModel *model;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) id selectedItem;

@end

@implementation BallDropViewController

@synthesize model = _model;
@synthesize isPlaying = _isPlaying;
@synthesize selectedItem = _selectedItem;
@synthesize context = _context;

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
	// Do any additional setup after loading the view, typically from a nib.
}

-(void)handleTap:(UITapGestureRecognizer *) tap
{
    NSLog(@"Tap!");
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *) touch 
{
    return ([touch locationInView:self.view].y < self.view.bounds.size.height - 100);
}


- (IBAction)newFilePressed:(UIButton *)sender {
    NSLog(@"new file");
}

- (IBAction)saveFilePressed:(UIButton *)sender {
    NSLog(@"save file");
}

- (IBAction)loadFilePressed:(UIButton *)sender {
    NSLog(@"load file");
}

- (IBAction)newBallSourcePressed:(UIButton *)sender {
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

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
