//
//  BallDropModel.m
//  BallDrop
//
//  Created by Peter Gibson on 8/23/12.
//  Copyright (c) 2012 Brown University. All rights reserved.
//

#import "BallDropModel.h"
#import "BallDropPhysics.h"

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
        [self addBallSourceAt:100];
        
    }
    
    return self;
}

/*
 Add a ball to the model at specified point
*/
- (void) addBallAt:(CGPoint)center
{
    BDBall newBall;
    newBall.centerPoint[0] = center.x;
    newBall.centerPoint[1] = center.y;
    newBall.Color[0] = 1;
    newBall.Color[1] = 0;
    newBall.Color[2] = 0;
    newBall.Color[3] = 1;
    [self.balls addObject:[NSValue value:&newBall withObjCType:@encode(BDBall)]];
}

/*
 Add a block to the model with specified endpoints
 */
- (void) addBlockFrom:(CGPoint)startPoint to:(CGPoint)endPoint
{
    BDBlock newBlock;
    newBlock.startPoint[0] = startPoint.x;
    newBlock.startPoint[1] = startPoint.y;
    newBlock.endPoint[0] = endPoint.x;
    newBlock.endPoint[1] = endPoint.y;    
    newBlock.Color[0] = 0;//(arc4random()%100)/100.0;
    newBlock.Color[1] = 0.2;//(arc4random()%100)/100.0;
    newBlock.Color[2] = 0.2;//(arc4random()%100)/100.0;
    newBlock.Color[3] = 1;
    [self.blocks addObject:[NSValue value:&newBlock withObjCType:@encode(BDBlock)]];
}


/*
 Begins a sequence to draw a new block.
*/
- (void) startNewBlockFrom:(CGPoint)startPoint
{
    [self addBlockFrom:startPoint to:startPoint];
}

/*
 Continues a sequence to draw a new block.
*/
- (void) updateNewBlockTo:(CGPoint)endPoint
{
    BDBlock block;
    NSValue *blockObject = [self.blocks lastObject];
    [blockObject getValue:&block];
    CGPoint p1 = CGPointMake(block.startPoint[0], block.startPoint[1]);
    [self.blocks removeLastObject];
    [self addBlockFrom:p1 to:endPoint];
}

/*
 Finishes a sequence to draw a new line. This function finalizes the line endpoint
*/
- (void) finalizeNewBlockTo:(CGPoint)endPoint
{    
    BDBlock block;
    NSValue *blockObject = [self.blocks lastObject];
    [blockObject getValue:&block];
    CGPoint p1 = CGPointMake(block.startPoint[0], block.startPoint[1]);
    [self.blocks removeLastObject];
    [self addBlockFrom:p1 to:endPoint];

}


/*
 Adds a ball source with a specified x position
*/
- (void)addBallSourceAt:(CGFloat) xpos
{   
    BDBallSource newSource;
    newSource.xpos = xpos;
    newSource.period = 4; 
    newSource.showBallPath = NO;
    [self.ballSources addObject:[NSValue value:&newSource withObjCType:@encode(BDBallSource)]];
}

- (void) advanceModelState:(float) deltaT
{
    //----Wall half planes (x, y, nx, ny)
	int i, j;
	float force;
	float collisionPt[2];
    
    
	//----Add new balls from the appropriate ball sources
	/*
     for (i = 0; i < model->numSources; i++) {
        
        
		//----Launch a ball from this source if appropriate. Note that at most 
		//----one ball is launched per deltaT time step.
		BDBallSource *source = &(model->sources[i]);
		if (source->timeToLaunch <= 0.0f) {
			source->timeToLaunch = source->period;
			if (model->numBalls < MAX_NUM_BALLS) {
				BDBall *ball = &(model->balls[model->numBalls++]);
				ball->centerPoint[0] = source->initialPosition[0];
				ball->centerPoint[1] = source->initialPosition[1];
				ball->velocity[0] = source->initialVelocity[0];
				ball->velocity[1] = source->initialVelocity[1];
				ball->radius = BALL_RADIUS;
			}
		} 
        
        
		//----Update the time to launch to the end of this time step
		source->timeToLaunch -= deltaT;
	}
    */
    /*
    BDBall ball;
    [[self.model.balls objectAtIndex:i] getValue:&ball];
    ball.velocity[1] = ball.velocity[1] + 0.1;
    ball.centerPoint[1] = ball.centerPoint[1] + ball.velocity[1];
    [self.model.balls replaceObjectAtIndex:i withObject:[NSValue value:&ball withObjCType:@encode(BDBall)]];
    */
    
	//----Test for and respond to collisions between balls
	for (j = 0; j < self.balls.count; j++) {
        BDBall ballA;
        [[self.balls objectAtIndex:j] getValue:&ballA];
		for (i = j+1; i < self.balls.count; i++) {
			BDBall ballB;
            [[self.balls objectAtIndex:i] getValue:&ballB];
			force = bdDetectBallBallCollision(&ballA, &ballB, deltaT, collisionPt);
			if (force > 0) {
				NSLog(@"collsion");
			}
            [self.balls replaceObjectAtIndex:i withObject:[NSValue value:&ballB withObjCType:@encode(BDBall)]];
		}
        [self.balls replaceObjectAtIndex:j withObject:[NSValue value:&ballA withObjCType:@encode(BDBall)]];
	}
    
/*    
	//----Test for and respond to collisions with the walls of the display window
	for (j = 0; j < model->numBalls; j++) {
		BDBall *ball = &(model->balls[j]);
		for (i = 0; i < model->numWalls; i++) {
			BDHalfPlane *wall = &(model->walls[i]);
			force = bdDetectBallHalfPlaneCollision(ball, wall, deltaT, collisionPt);
			if (force > 0) {
				// Add requests to play sound and render collision effect to the model
			}
		}
	}
*/    
    
	//----Test for and respond to collisions between balls and blocks
	for (j = 0; j < self.balls.count; j++) {
		BDBall ball;
        [[self.balls objectAtIndex:j] getValue:&ball];
		for (i = 0; i < self.blocks.count; i++) {
			BDBlock block;
            [[self.blocks objectAtIndex:i] getValue:&block];
			force = bdDetectBallBlockCollision(&ball, &block, deltaT, collisionPt);
			if (force > 0) {
                NSLog(@"collision");
				// Add requests to play sound and render collision effect to the model
			}
		}
        [self.balls replaceObjectAtIndex:j withObject:[NSValue value:&ball withObjCType:@encode(BDBall)]];
	}
    
    
	//----Advance the state of each ball in the ball drop model
	for (i = 0; i < self.balls.count; i++) {
		BDBall ball;
        [[self.balls objectAtIndex:i] getValue:&ball];
		bdAdvanceBallState(&ball, deltaT);
        [self.balls replaceObjectAtIndex:i withObject:[NSValue value:&ball withObjCType:@encode(BDBall)]];
	}
}

- (void) handleCollision: (id) c
{
    
}



@end

