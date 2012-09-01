//
//  BallDropEditBallSourceViewController.m
//  BallDrop
//
//  Created by Kristina Fedorenko on 8/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BallDropEditBallSourceViewController.h"


@interface BallDropEditBallSourceViewController ()


@end

@implementation BallDropEditBallSourceViewController

@synthesize deleteObjectDelegate = _deleteObjectDelegate;
@synthesize showPathSwitch = _showPathSwitch;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.contentSizeForViewInPopover = CGSizeMake(300.0, 300.0);
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
    [self setShowPathSwitch:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/*
 When the button is pressed, sends a message to the delegate to delete the selected object
*/
- (IBAction)deletePressed:(UIButton *)sender 
{
    NSLog(@"delete was pressed from edit ball source popover");
    [self.deleteObjectDelegate deleteObject:self];
    
}
@end
