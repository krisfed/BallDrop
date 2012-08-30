//
//  BallDropDeleteObjectDelegate.h
//  BallDrop
//
//  Created by Kristina Fedorenko on 8/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BallDropDeleteObjectDelegate <NSObject>
@required
-(void)deleteObject:(id)sender;

@end
