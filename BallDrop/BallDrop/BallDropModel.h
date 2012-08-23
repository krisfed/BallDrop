//
//  BallDropModel.h
//  BallDrop
//
//  Created by Peter Gibson on 8/23/12.
//  Copyright (c) 2012 Brown University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BallDropModel : NSObject

typedef struct {
    float Position[2]; //if doesn't work, change to 3
    float Color[4];
} Vertex;

typedef struct {
    CGPoint center;
    float vx;
    float vy;
    float Color[4];
} BallDropBall;

typedef struct {
    CGPoint p1;
    CGPoint p2;
    int soundType;
    int note;
    float Color[4];
} BallDropBlock;

typedef struct {
    float xpos;
    int period; //number of time ticks it waits to release each ball
    BOOL showBallPath;
} BallDropBallSource;

@property (nonatomic, strong)NSMutableArray *balls;
@property (nonatomic, strong)NSMutableArray *blocks;
@property (nonatomic, strong)NSMutableArray *ballSources;
@property (nonatomic, strong)NSMutableArray *collisions;



- (void) startNewBlockFrom:(CGPoint)startPoint;
- (void) updateNewBlockTo:(CGPoint)endPoint;
- (void) finalizeNewBlockTo:(CGPoint)endPoint;



@end
