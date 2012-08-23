//
//  BallDropStartUpViewController.m
//  BallDrop
//
//  Created by Peter Gibson on 8/23/12.
//  Copyright (c) 2012 Brown University. All rights reserved.
//

#import "BallDropStartUpViewController.h"

@interface BallDropStartUpViewController ()

@end

@implementation BallDropStartUpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.contentSizeForViewInPopover = CGSizeMake(400.0, 500.0);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
