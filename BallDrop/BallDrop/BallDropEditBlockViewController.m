//
//  BallDropEditBlockViewController.m
//  BallDrop
//
//  Created by Kristina Fedorenko on 8/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BallDropEditBlockViewController.h"

@interface BallDropEditBlockViewController ()

@end

@implementation BallDropEditBlockViewController

@synthesize deleteObjectDelegate = _deleteObjectDelegate;
@synthesize soundTypeSegmentedController = _soundTypeSegmentedController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.contentSizeForViewInPopover = CGSizeMake(250.0, 300.0);
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
    [self setSoundTypeSegmentedController:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (IBAction)deletePressed:(UIButton *)sender 
{
    
    NSLog(@"delete was pressed from edit block popover");
    [self.deleteObjectDelegate deleteObject:self];
}
@end
