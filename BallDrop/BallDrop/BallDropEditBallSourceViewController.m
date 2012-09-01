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
@synthesize periodStepper = _periodStepper;
@synthesize periodLabel = _periodLabel;

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
}

- (void)viewDidUnload
{
    [self setShowPathSwitch:nil];
    [self setPeriodStepper:nil];
    [self setPeriodLabel:nil];
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

/*
 Set the value of the period label to the value of the stepper
 when the value of the stepper changes
*/
- (IBAction)periodValueChanged 
{
    self.periodLabel.text = [NSString stringWithFormat:@"%.f", self.periodStepper.value];
}


/*
 Allows to set the period value
 (for both label and stepper)
*/
- (void)setPeriod:(int)period
{
    self.periodStepper.value = period;
    [self periodValueChanged];
}

@end
