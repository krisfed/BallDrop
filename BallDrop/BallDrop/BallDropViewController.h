//
//  BallDropViewController.h
//  BallDrop
//
//  Created by Kristina Fedorenko on 8/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

enum EditBlockState {
    EDIT_NO_BLOCK, 
    EDIT_START_HANDLE, 
    EDIT_END_HANDLE, 
    EDIT_BLOCK_POSITION
};


@interface BallDropViewController : GLKViewController <UIGestureRecognizerDelegate,UIPopoverControllerDelegate>

@end
