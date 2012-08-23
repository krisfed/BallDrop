//
//  BallDropModel.m
//  BallDrop
//
//  Created by Peter Gibson on 8/23/12.
//  Copyright (c) 2012 Brown University. All rights reserved.
//

#import "BallDropModel.h"

@interface BallDropModel ()

@end

@implementation BallDropModel

@synthesize balls = _balls;
@synthesize blocks = _blocks;
@synthesize ballSources = _ballSources;
@synthesize collisions = _collisions;


- (NSMutableArray*) balls 
{
    if (!_balls) {
        _balls = [[NSMutableArray alloc] init];
    }
    return _balls;
}

- (NSMutableArray*) blocks 
{
    if (!_blocks) {
        _blocks = [[NSMutableArray alloc] init];
    }
    return _blocks;
}

- (NSMutableArray*) ballSources 
{
    if (!_ballSources) {
        _ballSources = [[NSMutableArray alloc] init];
    }
    return _ballSources;
}

- (NSMutableArray*) collisions 
{
    if (!_collisions) {
        _collisions = [[NSMutableArray alloc] init];
    }
    return _collisions;
}

- (id) init
{
    self = [super init];
    if (self) {
        [self addBallAt:CGPointMake(0, 0)];
        [self addBallAt:CGPointMake(100, 100)];
        [self addBlockFrom:CGPointMake(200, 200) to:CGPointMake(300, 400)];
        
    }
    
    return self;
}

/*
 Add a ball to the model at specified point
*/
- (void) addBallAt:(CGPoint)center
{
    BallDropBall newBall;
    newBall.center = CGPointMake(center.x, center.y);
    newBall.Color[0] = 1;
    newBall.Color[1] = 0;
    newBall.Color[2] = 0;
    newBall.Color[3] = 1;
    [self.balls addObject:[NSValue value:&newBall withObjCType:@encode(BallDropBall)]];
}

/*
 Add a block to the model with specified endpoints
 */
- (void) addBlockFrom:(CGPoint)startPoint to:(CGPoint)endPoint
{
    BallDropBlock newBlock;
    newBlock.p1 = startPoint;//CGPointMake(startPoint.x, startPoint.y);
    newBlock.p2 = endPoint;//CGPointMake(endPoint.x, endPoint.y);
    newBlock.Color[0] = 1;//(arc4random()%100)/100.0;
    newBlock.Color[1] = 1;//(arc4random()%100)/100.0;
    newBlock.Color[2] = 1;//(arc4random()%100)/100.0;
    newBlock.Color[3] = 1;
    [self.blocks addObject:[NSValue value:&newBlock withObjCType:@encode(BallDropBlock)]];
}

- (void) updateModel 
{
    
}

- (void) handleCollision: (id) c
{
    
}



@end

