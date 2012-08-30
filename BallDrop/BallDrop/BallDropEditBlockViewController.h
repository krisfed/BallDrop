//
//  BallDropEditBlockViewController.h
//  BallDrop
//
//  Created by Kristina Fedorenko on 8/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BallDropDeleteObjectDelegate.h"


@interface BallDropEditBlockViewController : UIViewController

@property (nonatomic) id <BallDropDeleteObjectDelegate> deleteObjectDelegate;

- (IBAction)deletePressed:(UIButton *)sender;

@end

