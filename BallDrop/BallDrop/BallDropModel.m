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

- (void) initModel 
{
    
}

- (void) updateModel 
{
    
}

- (void) handleCollision: (id) c
{
    
}



@end

