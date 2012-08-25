//
//  BallDropModel.h
//  BallDrop
//
//  Created by Peter Gibson on 8/23/12.
//  Copyright (c) 2012 Brown University. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BALL_RADIUS 10
#define BLOCK_RADIUS 3

@interface BallDropModel : NSObject

typedef struct {
    float Position[2]; //if doesn't work, change to 3
    float Color[4];
} Vertex;

typedef struct {
    float centerPoint[2];	// Ball center point
	float velocity[2];		// Ball velocity
	float radius;			// Ball radius
    float Color[4];
} BDBall;

typedef struct {
    float startPoint[2]; // Block first end point
	float endPoint[2];	 // Block second end point
	float width;		 // Block width
	float length;		 // Distance between end points; Required by physics simulator
	float angle;		 // Angle from horizontal; Required by physics simulator
    int soundType;
    int note;
    float Color[4];
} BDBlock;

typedef struct {
    float xpos;
    int period; //number of time ticks it waits to release each ball
    BOOL showBallPath;
} BDBallSource;

typedef struct {
	float pointOnPlane[2];		// A point on the half plane
	float outwardUnitNormal[2];	// Outward normal of half plane; must have length one
} BDHalfPlane;


@property (nonatomic, strong) NSMutableArray *balls;
@property (nonatomic, strong) NSMutableArray *blocks;
@property (nonatomic, strong) NSMutableArray *ballSources;
@property (nonatomic, strong) NSMutableArray *collisions;


- (id)initWithHalfPlanesRight: (BDHalfPlane)right Left: (BDHalfPlane)left Top: (BDHalfPlane)top;
- (void) startNewBlockFrom:(CGPoint)startPoint;
- (void) updateNewBlockTo:(CGPoint)endPoint;
- (void) finalizeNewBlockTo:(CGPoint)endPoint;
- (void) addBallAt:(CGPoint)center;
- (void) addBallSourceAt:(CGFloat) xpos;
- (void) advanceModelState:(float) deltaT;
- (void) setHalfPlanes: (BDHalfPlane) plane0: (BDHalfPlane) plane1: (BDHalfPlane) plane2: (BDHalfPlane) plane3;


@end
