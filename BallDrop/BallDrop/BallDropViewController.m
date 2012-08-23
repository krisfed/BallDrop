//
//  BallDropViewController.m
//  BallDrop
//
//  Created by Kristina Fedorenko on 8/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BallDropViewController.h"

@interface BallDropViewController ()

@end

@implementation BallDropViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
}

- (IBAction)loadFilePressed:(UIButton *)sender {
}

- (IBAction)newBallSourcePressed:(UIButton *)sender {
}

- (IBAction)playStopPressed:(UIButton *)sender {
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
