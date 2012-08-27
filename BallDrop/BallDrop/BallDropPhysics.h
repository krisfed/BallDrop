//-----------------------------------------------------------------------------------
//  Filename: BallDropPhysics.h
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
//	Interface for modeling the physics of a simple ball drop model
//	Version 1.0
//	Copyright 2012, PBMK Co., 61 Crescent St., Cambridge, MA, 02138.
//	All rights reserved.
//-----------------------------------------------------------------------------------

#include "BallDropModel.h"

//-----------------------------------------------------------------------------------
//	Constants
//-----------------------------------------------------------------------------------
#define BALL_MASS				0.1		// some units ... (affects drag forces)
#define GRAVITY                 -800.0	// pixels per second^2
#define DRAG_COEFFICIENT		0.01	// force applied to oppose forward velocity
#define COLLISION_EFFICIENCY	0.80	// % velocity conserved after collision
#define RESTING_VELOCITY		20.0	// resting velocity thresholod for collisions

//-----------------------------------------------------------------------------------
//	SELECTING ELEMENTS IN THE MODEL
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
//	Get the distance from the specified point to the specified object. These functions
//	can be used to find an object within a specified distance from a selection point.
//-----------------------------------------------------------------------------------
float bdGetDistanceBetweenPoints(float point1[2], float point2[2]);
float bdGetDistanceToBall (float point[2], BDBall *ball);
float bdGetDistanceToBlock (float point[2], BDBlock *block);
float bdGetDistanceToHalfPlane (float point[2], BDHalfPlane *halfPlane);


//-----------------------------------------------------------------------------------
//	SIMULATING INTERACTIONS BETWEEN ELEMENTS OF THE MODEL
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
//	Detect the next collision (if any) in the given time step deltaT between the 
//	specified objects. If a collision is detected, the ball states are adjusted to
//	account for the collision. These functions set the position of the collision 
//	point and return the force of the collision; if no collision occurs, the collision
//	point is not set and zero is returned.
//-----------------------------------------------------------------------------------
float bdDetectBallBallCollision (BDBall *ballA, BDBall *ballB, float deltaT, 
								 float *collisionPoint);
float bdDetectBallBlockCollision (BDBall *ball, BDBlock *block, float deltaT, 
								  float *collisionPoint);
float bdDetectBallHalfPlaneCollision (BDBall *ball, BDHalfPlane *halfPlane, 
									  float deltaT, float *collisionPoint);


//-----------------------------------------------------------------------------------
//	Advance the state of the specified ball by the given time step deltaT. This 
//	function assumes that the ball state has already been adjusted to account for
//	collisions during deltaT using 
//-----------------------------------------------------------------------------------
void bdAdvanceBallState (BDBall *ball, float deltaT);