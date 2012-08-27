//
//  BallDropViewController.h
//  BallDrop
//
//  Created by Kristina Fedorenko on 8/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

enum EditObjectState {
    EDIT_NO_OBJECT,       //no editing of the block or ball source is happening 
    EDIT_START_HANDLE,    //start point of the block is being edited
    EDIT_END_HANDLE,      //end point of the block is being edited
    EDIT_BLOCK_POSITION,  //block position is being edited
    EDIT_SOURCE_POSITION  //ball source position is being edited
};


@interface BallDropViewController : GLKViewController <UIGestureRecognizerDelegate,UIPopoverControllerDelegate>

@end
