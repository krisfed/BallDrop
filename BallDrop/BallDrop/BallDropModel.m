//
//  BallDropModel.m
//  BallDrop
//
//  Created by Peter Gibson on 8/23/12.
//  Copyright (c) 2012 Brown University. All rights reserved.
//

#import "BallDropModel.h"
#import "BallDropPhysics.h"
#import "BallDropSound.h"

@interface BallDropModel ()
{
    BDHalfPlane _halfPlanes[3]; //define the right, left, and top border
}
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

- (void) setHalfPlanesRight: (BDHalfPlane)right Left:(BDHalfPlane)left Top: (BDHalfPlane)top
{
    _halfPlanes[0] = right;
    _halfPlanes[1] = left;
    _halfPlanes[2] = top;    
}


- (id)initWithHalfPlanesRight: (BDHalfPlane)right Left: (BDHalfPlane)left Top: (BDHalfPlane)top
{
    self = [super init];
    if (self) {
        _halfPlanes[0] = right;
        _halfPlanes[1] = left;
        _halfPlanes[2] = top;
        
        
        // one source by default as example
        [self addBallSourceAt:100];
        
        // four blocks define sink
        float sinkLength    = 270;
        float sinkMinHeight = 70;
        float sinkMaxHeight = 120;
        [self addBlockFrom:CGPointMake(sinkLength, 0) 
                        to:CGPointMake(sinkLength, sinkMinHeight)];
        [self addBlockFrom:CGPointMake(0, sinkMaxHeight) 
                        to:CGPointMake(sinkLength, sinkMinHeight)];
        [self addBlockFrom:CGPointMake(_halfPlanes[0].pointOnPlane[0] - sinkLength, 0) 
                        to:CGPointMake(_halfPlanes[0].pointOnPlane[0] - sinkLength, sinkMinHeight)];
        [self addBlockFrom:CGPointMake(_halfPlanes[0].pointOnPlane[0], sinkMaxHeight) 
                        to:CGPointMake(_halfPlanes[0].pointOnPlane[0] - sinkLength, sinkMinHeight)];
        
        
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
    
    int harmonicNote = (arc4random() % 6); //randomly generates a harmonic note and
    //assign the key accordingly
    switch (harmonicNote) {
        case 0:
            newBlock.note = 0;
            break;
        case 1:
            newBlock.note = 2;
            break;
        case 2:
            newBlock.note = 5;
            break;
        case 3:
            newBlock.note = 7;
            break;
        case 4:
            newBlock.note = 9;
            break;
        case 5:
            newBlock.note = 12;
            break;
    }
    
    newBlock.soundType = 1;
    newBlock.width = 2*BLOCK_RADIUS;
    newBlock = [self recalculateAngleAndLengthForBlock:newBlock];
    
    [self.blocks addObject:[NSValue value:&newBlock withObjCType:@encode(BDBlock)]];
}


/*
 Calculates and updates block's angle and length based
 on the block's endpoints information; 
 Takes in the block to be updated, returns the updated block
*/
- (BDBlock)recalculateAngleAndLengthForBlock:(BDBlock)block
{
    float dx = block.endPoint[0] - block.startPoint[0];
    float dy = block.endPoint[1] - block.startPoint[1];
    block.angle = atan2f(dy,dx);
    block.length = sqrtf(dx*dx + dy*dy);
    
    return block;
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
 Finishes a sequence to draw a new block. This function finalizes the block endpoint
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
 Changes the specified block's endpoint to the one provided
 Returns the pointer to the modified block
*/
- (id)updateBlock:(id)blockObject withEndpoint:(float[2])newEndpoint
{
    
    BDBlock block;
    [blockObject getValue:&block];
    block.endPoint[0] = newEndpoint[0];
    block.endPoint[1] = newEndpoint[1];
    block = [self recalculateAngleAndLengthForBlock:block];
    [self.blocks removeObject:blockObject];
    [self.blocks addObject:[NSValue value:&block withObjCType:@encode(BDBlock)]];
    return [self.blocks lastObject];
}

/*
 Changes the specified block's startpoint to the one provided
 Returns the pointer to the modified block
 */
- (id)updateBlock:(id)blockObject withStartpoint:(float[2])newStartpoint
{
    
    BDBlock block;
    [blockObject getValue:&block];
    block.startPoint[0] = newStartpoint[0];
    block.startPoint[1] = newStartpoint[1];
    block = [self recalculateAngleAndLengthForBlock:block];
    [self.blocks removeObject:blockObject];
    [self.blocks addObject:[NSValue value:&block withObjCType:@encode(BDBlock)]];
    return [self.blocks lastObject];
}

/*
 Moves the specified block to the new position provided
 Returns the pointer to the modified block
*/
- (id)moveBlock: (id)blockObject toPosition:(float[2])newPosition
{
    BDBlock block;
    [blockObject getValue:&block];
    float center[2];
    center[0] = block.startPoint[0] + (block.endPoint[0] - block.startPoint[0])/2.0;
    center[1] = block.startPoint[1] + (block.endPoint[1] - block.startPoint[1])/2.0;
    float dx = newPosition[0] - center[0];
    float dy = newPosition[1] - center[1];
    block.startPoint[0] += dx;
    block.endPoint[0]   += dx;
    block.startPoint[1] += dy;
    block.endPoint[1]   += dy;
    [self.blocks removeObject:blockObject];
    [self.blocks addObject:[NSValue value:&block withObjCType:@encode(BDBlock)]];
    return [self.blocks lastObject];
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
                
			}
            [self.balls replaceObjectAtIndex:i withObject:[NSValue value:&ballB withObjCType:@encode(BDBall)]];
		}
        [self.balls replaceObjectAtIndex:j withObject:[NSValue value:&ballA withObjCType:@encode(BDBall)]];
	}
    
    
	//----Test for and respond to collisions with the walls of the display window
	for (j = 0; j < self.balls.count; j++) {
		BDBall ball;
        [[self.balls objectAtIndex:j] getValue:&ball];
		for (i = 0; i < sizeof(_halfPlanes)/sizeof(BDHalfPlane); i++) {
			force = bdDetectBallHalfPlaneCollision(&ball, &(_halfPlanes[i]), deltaT, collisionPt);
			if (force > 0) {
				// Add requests to play sound and render collision effect to the model
			}
		}
        [self.balls replaceObjectAtIndex:j withObject:[NSValue value:&ball withObjCType:@encode(BDBall)]];
	}
   
    
	//----Test for and respond to collisions between balls and blocks
	for (j = 0; j < self.balls.count; j++) {
		BDBall ball;
        [[self.balls objectAtIndex:j] getValue:&ball];
		for (i = 0; i < self.blocks.count; i++) {
			BDBlock block;
            [[self.blocks objectAtIndex:i] getValue:&block];
			force = bdDetectBallBlockCollision(&ball, &block, deltaT, collisionPt);
			if (force > 0) {
                //ignore the first four blocks
                if (i>3) {
                    [BallDropSound makeSoundofType:block.soundType ofNote:block.note];
                }
			}
		}
        [self.balls replaceObjectAtIndex:j withObject:[NSValue value:&ball withObjCType:@encode(BDBall)]];
	}
    
    
	//----Advance the state of each ball in the ball drop model
	for (i = 0; i < self.balls.count; i++) {
		BDBall ball;
        [[self.balls objectAtIndex:i] getValue:&ball];
		bdAdvanceBallState(&ball, deltaT);
        
        //remove ball if it fell bellow the area of the screen, otherwise advance it
        if (ball.centerPoint[1] < 0) {
            [self.balls removeObjectAtIndex:i];
        } else {
            [self.balls replaceObjectAtIndex:i withObject:[NSValue value:&ball withObjCType:@encode(BDBall)]];
        }
        
	}
}

- (void) handleCollision: (id) c
{
    
}



@end

