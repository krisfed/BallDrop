//
//  BallDropEditBallSourceViewController.h
//  BallDrop
//
//  Created by Kristina Fedorenko on 8/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BallDropDeleteObjectDelegate.h"

@interface BallDropEditBallSourceViewController : UIViewController

@property (nonatomic) id <BallDropDeleteObjectDelegate> deleteObjectDelegate;

@property (strong, nonatomic) IBOutlet UISwitch *showPathSwitch;
- (IBAction)deletePressed:(UIButton *)sender;

@end
