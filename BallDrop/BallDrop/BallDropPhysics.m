//-----------------------------------------------------------------------------------
//  Filename: BallDropPhysics.c
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
//	Implementation of a simple ball drop model
//	Version 1.0
//	Copyright 2012, PBMK Co., 61 Crescent St., Cambridge, MA, 02138.
//	All rights reserved.
//-----------------------------------------------------------------------------------


//-----------------------------------------------------------------------------------
//	Required include files
//-----------------------------------------------------------------------------------
#include "stdlib.h"
#include "math.h"
#include "BallDropPhysics.h"


//-----------------------------------------------------------------------------------
//	PRIVATE FUNCTION PROTOCOLS
//-----------------------------------------------------------------------------------
static void GetVectorDistFromBlock (float point[2], BDBlock *block, float *vectorDist);
static float GetSignedDistFromHalfPlane (float point[2], BDHalfPlane *halfPlane);
static float GetBallBallCollisionTime (BDBall *ballA, BDBall *ballB, float deltaT);
static float GetBallBlockCollisionTime (BDBall *ball, BDBlock *block, float deltaT, float *forceDir);
static float GetBallPlaneCollisionTime (BDBall *ball, BDHalfPlane *plane, float 
deltaT);


//-----------------------------------------------------------------------------------
//	IMPEMENTATION OF PUBLIC FUNCTIONS
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
//	SELECTING ELEMENTS IN THE MODEL
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
//  Get the distance between specified points
//-----------------------------------------------------------------------------------
float bdGetDistanceBetweenPoints(float point1[2], float point2[2])
{
    float dx = point2[0] - point1[0];
	float dy = point2[1] - point1[1];
	return(sqrt(dx * dx + dy * dy));
}
//-----------------------------------------------------------------------------------
//	Get the distance from the specified point to the specified ball. This function
//	can be used to find an object within a specified distance from a selection point.
//-----------------------------------------------------------------------------------
float bdGetDistanceToBall (float point[2], BDBall *ball)
{
	float dx = ball->centerPoint[0] - point[0];
	float dy = ball->centerPoint[1] - point[1];
	return(sqrt(dx * dx + dy * dy));
}


//-----------------------------------------------------------------------------------
//	Get the distance from the specified point to the specified block. This function
//	can be used to find an object within a specified distance from a selection point.
//-----------------------------------------------------------------------------------
float bdGetDistanceToBlock (float point[2], BDBlock *block)
{
	float vectorDist[2];
	GetVectorDistFromBlock(point, block, vectorDist);
	return (sqrt(vectorDist[0] * vectorDist[0] + vectorDist[1] * vectorDist[1]));
}


//-----------------------------------------------------------------------------------
//	Get the distance from the specified point to the specified half plane. This 
//	function can be used to find an object within a specified distance from a 
//	selection point.
//-----------------------------------------------------------------------------------
float bdGetDistanceToHalfPlane (float point[2], BDHalfPlane *halfPlane)
{
	float dist = GetSignedDistFromHalfPlane(point, halfPlane);
	return (fabs(dist));
}


//-----------------------------------------------------------------------------------
//	SIMULATING INTERACTIONS BETWEEN ELEMENTS OF THE MODEL
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
//	Detect the next collision (if any) in the given time step deltaT between the 
//	specified balls. If a collision is detected, the ball states are adjusted to
//	account for the collision. This function sets the position of the collision 
//	point and return the force of the collision; if no collision occurs, the collision
//	point is not set and zero is returned.
//-----------------------------------------------------------------------------------
float bdDetectBallBallCollision (BDBall *ballA, BDBall *ballB, float deltaT, 
float *collisionPoint)
{
	float xA, yA;
	float xB, yB;
	float vF[2];
	float uF[2];
	float length;
	float vAParallel;
	float vBParallel;
	float vAPerpendicular;
	float vBPerpendicular;


	//----Test to see if the balls collide between the current time and deltaT after
	//----the current time
	float timeToCollision = GetBallBallCollisionTime(ballA, ballB, deltaT);
	if (timeToCollision < 0) return 0;


	//----Get the ball positions at the collision time
	xA = ballA->centerPoint[0] + timeToCollision * ballA->velocity[0];
	yA = ballA->centerPoint[1] + timeToCollision * ballA->velocity[1];
	xB = ballB->centerPoint[0] + timeToCollision * ballB->velocity[0];
	yB = ballB->centerPoint[1] + timeToCollision * ballB->velocity[1];


	//----The collision applies an equal and opposite force to both balls along the
	//----vector joining their centers. Determine a unit vector from the center of
	//----ballA to the center of ballB as this force direction vector, vF. Let uF
	//----be the unit vector perpendicular to vF. If the ball positions are 
	//----coincident, use an arbitrary force direction.
	vF[0] = xB - xA;
	vF[1] = yB - yA;
	length = sqrt(vF[0] * vF[0] + vF[1] * vF[1]);
	if (length > 0.00001f) {
		vF[0] /= length;
		vF[1] /= length;
	} else {
		vF[0] = 0.0f;
		vF[1] = 1.0f;
	}
	uF[0] = -vF[1];
	uF[1] =  vF[0];


	//----It can be shown, for a collision between two balls of equal mass that
	//----conserves both momentum and kinetic energy, the ball velocities parallel to 
	//----the force direction vector are exchanged while the ball velocities 
	//----perpendicular to the force direction vector are preserved. Using this
	//----observation, the ball velocities after the collision are computed as 
	//----follows.
	vAPerpendicular = ballA->velocity[0] * vF[0] + ballA->velocity[1] * vF[1];
	vBPerpendicular = ballB->velocity[0] * vF[0] + ballB->velocity[1] * vF[1];
	vAParallel = ballA->velocity[0] * uF[0] + ballA->velocity[1] * uF[1];
	vBParallel = ballB->velocity[0] * uF[0] + ballB->velocity[1] * uF[1];
	ballA->velocity[0] = vBPerpendicular * vF[0] + vAParallel * uF[0];
	ballA->velocity[1] = vBPerpendicular * vF[1] + vAParallel * uF[1];
	ballB->velocity[0] = vAPerpendicular * vF[0] + vBParallel * uF[0];
	ballB->velocity[1] = vAPerpendicular * vF[1] + vBParallel * uF[1];


	//----Back up the ball positions to the current time
	ballA->centerPoint[0] = xA - timeToCollision * ballA->velocity[0];
	ballA->centerPoint[1] = yA - timeToCollision * ballA->velocity[1];
	ballB->centerPoint[0] = xB - timeToCollision * ballB->velocity[0];
	ballB->centerPoint[1] = yB - timeToCollision * ballB->velocity[1];
    return 1;
}


//-----------------------------------------------------------------------------------
//	Detect the next collision (if any) in the given time step deltaT between the 
//	specified ball and block. If a collision is detected, the ball state is adjusted 
//	to account for the collision. This function sets the position of the collision 
//	point and return the force of the collision; if no collision occurs, the collision
//	point is not set and zero is returned.
//-----------------------------------------------------------------------------------
float bdDetectBallBlockCollision (BDBall *ball, BDBlock *block, float deltaT, 
float *collisionPoint)
{
	float forceDir[2];
	float xCollision;
	float yCollision;
	float vParallel;
	float vPerpendicular;
	float timeToCollision;


	//----Test to see if the ball collides with the block between the current time and 
	//----deltaT after the current time
	timeToCollision = GetBallBlockCollisionTime(ball, block, deltaT, forceDir);
	if (timeToCollision < 0) return 0;


	//----Get the ball position at the collision time
	xCollision = ball->centerPoint[0] + timeToCollision * ball->velocity[0];
	yCollision = ball->centerPoint[1] + timeToCollision * ball->velocity[1];


	//----The collision reverses the component of the ball's velocity that is in the
	//----direction of the force vector. Determine the components of the ball's 
	//----velocity that are parallel and perpendicular to the force direction.
	vParallel = ball->velocity[0] * forceDir[0] + ball->velocity[1] * forceDir[1];
	vPerpendicular = -ball->velocity[0] * forceDir[1] + ball->velocity[1] * forceDir[0];

			
	//----Set the ball's post-collision velocity. After the collision, the component
	//----of the ball's velocity parallel to the force is in the outward direction.
	//----Small velocities are damped out to simulate resting contact.
	vParallel = (-vParallel - RESTING_VELOCITY) * COLLISION_EFFICIENCY;
	if (vParallel < RESTING_VELOCITY) vParallel = 0;
	ball->velocity[0] = vParallel * forceDir[0] - vPerpendicular * forceDir[1];
	ball->velocity[1] = vParallel * forceDir[1] + vPerpendicular * forceDir[0];


	//----Back up the ball's position to the current time
	ball->centerPoint[0] = xCollision - timeToCollision * ball->velocity[0];
	ball->centerPoint[1] = yCollision - timeToCollision * ball->velocity[1];
    return 1;
}


//-----------------------------------------------------------------------------------
//	Detect the next collision (if any) in the given time step deltaT between the 
//	specified ball and half plane. If a collision is detected, the ball state is 
//	adjusted to account for the collision. This function sets the position of the 
//	collision point and return the force of the collision; if no collision occurs, 
//	the collision point is not set and zero is returned.
//-----------------------------------------------------------------------------------
float bdDetectBallHalfPlaneCollision (BDBall *ball, BDHalfPlane *plane, float deltaT, 
float *collisionPoint)
{
	//----Test to see if the ball collides with the half plane between the current 
	//----time and deltaT after the current time
	float nx, ny;
	float vParallel;
	float vPerpendicular;
	float timeToCollision = GetBallPlaneCollisionTime(ball, plane, deltaT);
	if (timeToCollision < 0) return 0;


	//----Get the ball position at the collision time
	collisionPoint[0] = ball->centerPoint[0] + timeToCollision * ball->velocity[0];
	collisionPoint[1] = ball->centerPoint[1] + timeToCollision * ball->velocity[1];


	//----The collision reverses the component of the ball's velocity that is 
	//----perpendicular to the plane. Determine the parallel and perpendicular 
	//----components of the ball's velocity
	nx = plane->outwardUnitNormal[0];
	ny = plane->outwardUnitNormal[1];
	vPerpendicular = ball->velocity[0] * nx + ball->velocity[1] * ny;
	vParallel = -ball->velocity[0] * ny + ball->velocity[1] * nx;

			
	//----Set the ball's post-collision velocity. After the collision, the component
	//----of the ball's velocity perpendicular to the surface is in the outward 
	//----direction. Small velocities are damped out to simulate resting contact.
	vPerpendicular = (-vPerpendicular - RESTING_VELOCITY) * COLLISION_EFFICIENCY;
	if (vPerpendicular < RESTING_VELOCITY) vPerpendicular = 0;
	ball->velocity[0] = vPerpendicular * nx - vParallel * ny;
	ball->velocity[1] = vPerpendicular * ny + vParallel * nx;


	//----Back up the ball's position to the current time
	ball->centerPoint[0] = collisionPoint[0] - timeToCollision * ball->velocity[0];
	ball->centerPoint[1] = collisionPoint[1] - timeToCollision * ball->velocity[1];
    return 1;
}


//-----------------------------------------------------------------------------------
//	Advance the state of the specified ball by the given time step deltaT. This 
//	function assumes that the ball state has already been adjusted to account for
//	collisions during deltaT using 
//-----------------------------------------------------------------------------------
void bdAdvanceBallState (BDBall *ball, float deltaT)
{
	float dx = ball->velocity[0];
	float dy = ball->velocity[1];
	float dvx = (-DRAG_COEFFICIENT * ball->velocity[0]) / BALL_MASS;
	float dvy = GRAVITY - (DRAG_COEFFICIENT * ball->velocity[1]) / BALL_MASS;
	ball->centerPoint[0] += deltaT * dx;
	ball->centerPoint[1] += deltaT * dy;
	ball->velocity[0] += deltaT * dvx;
	ball->velocity[1] += deltaT * dvy;
}


//-----------------------------------------------------------------------------------
//	IMPEMENTATION OF PRIVATE FUNCTIONS
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
//	Find the real roots of the quadratic expression Ax^2 + BX + C = 0. This function
//	sets the elements of roots (the first element if there is one root, and both
//	elements if there are two roots) and returns the number of real roots.
//-----------------------------------------------------------------------------------
static int SolveQuadratic (float a, float b, float c, float roots[2])
{
	//----Solve degenerate cases
	float p, q;
	if (a == 0) {
		if (b == 0) {
			if (c == 0) {
				//----The expression is true for all t so use t = 0
				roots[0] = 0;
				return(1);
			}
			return(0);
		}
		roots[0] = -c / b;
		return(1);
	}


	//----Solve using the quadratic formula: x = -b/2a +/- sqrt((b/2a)^2 - c/a). First 
	//----test for non-real and repeated roots.
	p = -0.5 * b / a;
	q = p * p - c / a;
	if (q < 0) return(0);
	else if (q == 0) {
		roots[0] = p;
		return(1);
	}
	q = sqrt(q);
	roots[0] = p - q;
	roots[1] = p + q;
	return(2);
}


//-----------------------------------------------------------------------------------
//	Get the vector distance from the specified block to the specified point
//-----------------------------------------------------------------------------------
static void GetVectorDistFromBlock (float point[2], BDBlock *block, float *vectorDist)
{
	float blockDir[2] = { cos(block->angle), sin(block->angle) };
	float vcp[2] = {point[0] - block->startPoint[0], point[1] - block->startPoint[1]};
	float projOntoBlock = vcp[0] * blockDir[0] + vcp[1] * blockDir[1];
	if (projOntoBlock < 0) {


		//----The ball is closest to the first endpoint
		vectorDist[0] = point[0] - block->startPoint[0];
		vectorDist[1] = point[1] - block->startPoint[1];


	} else if (projOntoBlock > block->length) {


		//----The ball is closest to the second endpoint
		vectorDist[0] = point[0] - block->endPoint[0];
		vectorDist[1] = point[1] - block->endPoint[1];


	} else {


		//----The ball is closest to the block center section
		float blockNorm[2] = { -blockDir[1], blockDir[0] };
		float projOntoN = vcp[0] * blockNorm[0] + vcp[1] * blockNorm[1];
		vectorDist[0] = projOntoN * blockNorm[0];
		vectorDist[1] = projOntoN * blockNorm[1];
	}
}


//-----------------------------------------------------------------------------------
//	Get the signed distance from the specified half plane to the specified point
//-----------------------------------------------------------------------------------
static float GetSignedDistFromHalfPlane (float point[2], BDHalfPlane *halfPlane)
{
	float nx = halfPlane->outwardUnitNormal[0];
	float ny = halfPlane->outwardUnitNormal[1];
	float dx = point[0] - halfPlane->pointOnPlane[0];
	float dy = point[1] - halfPlane->pointOnPlane[1];
	float dist = dx * nx + dy * ny;
	return(dist);
}


//-----------------------------------------------------------------------------------
//	If the ball collides with plane between the current time and deltaT after the 
//	current time, set tHit to the collision time (i.e., a value between zero and 
//	deltaT). Otherwise, return a negative value.
//-----------------------------------------------------------------------------------
static float GetBallPlaneCollisionTime (BDBall *ball, BDHalfPlane *plane, float 
deltaT)
{
	//----First test to see if the ball is already inside the half plane
	float hitTime;
	float nx = plane->outwardUnitNormal[0];
	float ny = plane->outwardUnitNormal[1];
	float initialHeight = GetSignedDistFromHalfPlane(ball->centerPoint, plane);
	float dh = ball->velocity[0] * nx + ball->velocity[1] * ny;
	if (initialHeight <= BALL_RADIUS) {


		//----The ball is inside the half plane. If the ball velocity is inwards, the 
		//----collision time is zero. Otherwise, let the ball continue to move 
		//----outwards.
		if (dh < 0) return(0);
		else return(-1);
	}


	//----The ball collides with the half plane when height of the ball is less than
	//----the ball radius, i.e., when initialHeight + t*dh = BALL_RADIUS
	if (dh == 0) return(-1);
	hitTime = (BALL_RADIUS - initialHeight) / dh;
	if ((hitTime < 0) || (hitTime > deltaT)) return(-1);
	else return(hitTime);
}


//-----------------------------------------------------------------------------------
//	If ballA and ballB collide between the current time and deltaT after the current
//	time, set tHit to the collision time (i.e., a value between zero and deltaT). 
//	Otherwise, return a negative value.
//-----------------------------------------------------------------------------------
static float GetBallBallCollisionTime (BDBall *ballA, BDBall *ballB, float deltaT)
{
	int numRoots;
	float roots[2];
	float A;
	float B;
	float C;
	float dvx = ballB->velocity[0] - ballA->velocity[0];
	float dvy = ballB->velocity[1] - ballA->velocity[1];
	float dx = ballB->centerPoint[0] - ballA->centerPoint[0];
	float dy = ballB->centerPoint[1] - ballA->centerPoint[1];
	float sqrDist = dx * dx + dy * dy;


	//----Handle the case when the balls are already colliding. If they are colliding
	//----and moving appart, return no collision. Otherwise, return a collision time
	//----of zero.
	if (sqrDist < 4 * BALL_RADIUS * BALL_RADIUS) {
		if (dx * dvx + dy * dvy > 0) return(-1.0f);
		else return(0);
	}


	//----The balls collide when their positions are separated by twice the radius of 
	//----the balls. If we parameterize the ball positions as P = P0 + tv, where P0 
	//----and v are the position of the ball at the current time and the velocity of 
	//----the ball between t = 0 and t = deltaT, then the collision time satisfies the
	//----quadratic equation ||(PB0 + tvB) - (PA0 - tvA)||^2 = (2R)^2. Determine the 
	//----coefficients of this quadratic equation and find its roots.
	A = dvx * dvx + dvy * dvy;
	B = 2 * (dx * dvx + dy * dvy);
	C = sqrDist - 4 * BALL_RADIUS * BALL_RADIUS;
	numRoots = SolveQuadratic(A, B, C, roots);


	//----Return the smallest real root between 0 and deltaT if it exists. Otherwise
	//----return -1.
	if (numRoots == 0) return(-1);
	if (numRoots == 1) {
		if ((roots[0] < 0) || (roots[0] > deltaT)) return(-1);
		else return(roots[0]);
	} else {
		float t = roots[0];
		if (t < 0) t = roots[1];
		else if (roots[1] > 0 && roots[1] < t) t = roots[1];
		if (t > deltaT) return(-1);
		else return(t);
	}
}


//-----------------------------------------------------------------------------------
//	If the specified ball collides with the specified block between the current time 
//	and deltaT after the current time, set tHit to the collision time (i.e., a value 
//	between zero and deltaT). Otherwise, return a negative value.
//-----------------------------------------------------------------------------------
static float GetBallBlockCollisionTime (BDBall *ball, BDBlock *block, float deltaT, 
float *forceDir)
{
	//----First, test to see if the ball is already colliding with the block
	float vectorDist[2];
	float tMin = 2.0f * deltaT;
	float r = BALL_RADIUS + BLOCK_RADIUS;
	GetVectorDistFromBlock(ball->centerPoint, block, vectorDist);
	if (vectorDist[0] * vectorDist[0] + vectorDist[1] * vectorDist[1] < r * r) {


		//----The ball is initially colliding with the block. If it is moving away, 
		//----return no collision. Otherwise set the force direction vector and return 
		//----a collision time of zero.
		if (ball->velocity[0] * vectorDist[0] + ball->velocity[1] * vectorDist[1] > 0)
		return(-1.0f);
		else {
			float mag;
			mag = sqrt(vectorDist[0] * vectorDist[0] + vectorDist[1] * vectorDist[1]);
			if (mag > 0) {
				forceDir[0] = vectorDist[0] / mag;
				forceDir[1] = vectorDist[1] / mag;
			} else {
				forceDir[0] = 0.0f;
				forceDir[1] = 0.0f;
			}
			return(0);
		}
	}


	//----The ball is initially outside the block. Find the first time in the time
	//----interval (if any) when it collides with the central section of the block
	//----i.e., the first time in the time interval when the magnitude of the dot 
	//----product of the block unit normal vector and the vector from the first 
	//----endpoint of the block to the ball center point is equal to the sum of the 
	//----ball radius and half the block width AND the ball center is between the 
	//----block endpoints
	{
		float x0 = block->startPoint[0];
		float y0 = block->startPoint[1];
		float nx = -sin(block->angle);
		float ny =  cos(block->angle);
		float vcp[2] = { ball->centerPoint[0] - x0, ball->centerPoint[1] - y0 };
		float vcpDotN = vcp[0] * nx + vcp[1] * ny;
		float vDotN = ball->velocity[0] * nx + ball->velocity[1] * ny;
		float t1 = (r - vcpDotN) / vDotN;
		float t2 = (-r - vcpDotN) / vDotN;
		if ((t1 > 0) && (t1 < deltaT)) {
			float hitPt[2] = { ball->centerPoint[0] + t1 * ball->velocity[0],
			ball->centerPoint[1] + t1 * ball->velocity[1]};
			float vch[2] = { hitPt[0] - x0, hitPt[1] - y0 };
			float proj = vch[0] * cos(block->angle) + vch[1] * sin(block->angle);
			if ((0 <= proj) && (proj < block->length)) {
				tMin = t1;
				if (vcpDotN >= 0) {
					forceDir[0] = nx;
					forceDir[1] = ny;
				} else {
					forceDir[0] = -nx;
					forceDir[1] = -ny;
				}
			}
		}
		if ((t2 > 0) && (t2 < deltaT) && (t2 < tMin)) {
			float hitPt[2] = { ball->centerPoint[0] + t2 * ball->velocity[0],
			ball->centerPoint[1] + t2 * ball->velocity[1]};
			float vch[2] = { hitPt[0] - x0, hitPt[1] - y0 };
			float proj = vch[0] * cos(block->angle) + vch[1] * sin(block->angle);
			if ((0 <= proj) && (proj < block->length)) {
				tMin = t2;
				if (vcpDotN >= 0) {
					forceDir[0] = nx;
					forceDir[1] = ny;
				} else {
					forceDir[0] = -nx;
					forceDir[1] = -ny;
				}
			}
		}
	}


	//----Find the first time in the time interval (if any) when the ball intersects
	//----the block ends. The ball collide with an end of the block when the distance
	//----from the ball center point to the end point is equal to the sum of the ball
	//----radius and half the block width. If we parametrize the position of the ball
	//----center point as P(t) = P + tv and let P0 be the end point position, then 
	//----the collision time satisfies the quadratic equation ||P + tv - P0||^2 = 
	//----(rBall + rBlock)^2. Determine the coefficients of this quadratic equation 
	//----and find its roots. Update the intersection time if appropriate.
	{
		float A, B, C;
		float didHit;
		float numRoots;
		float roots[2];
		float vx = ball->velocity[0];
		float vy = ball->velocity[1];
		float x0 = block->startPoint[0];
		float y0 = block->startPoint[1];
		float vp0p[2] = { ball->centerPoint[0] - x0, ball->centerPoint[1] - y0 };
		float x1 = block->endPoint[0];
		float y1 = block->endPoint[1];
		float vp1p[2] = { ball->centerPoint[0] - x1, ball->centerPoint[1] - y1 };


		//----First endpoint
		A = vx * vx + vy * vy;
		B = 2 * (vp0p[0] * vx + vp0p[1] * vy);
		C = vp0p[0] * vp0p[0] + vp0p[1] * vp0p[1] - r * r;
		numRoots = SolveQuadratic(A, B, C, roots);
		didHit = 0;
		if (numRoots == 1) {
			if ((roots[0] > 0) && (roots[0] < deltaT) && (roots[0] < tMin)) {
				tMin = roots[0];
				didHit = 1;
			}
		} else if (numRoots == 2) {
			if ((roots[0] > 0) && (roots[0] < deltaT) && (roots[0] < tMin)) {
				tMin = roots[0];
				didHit = 1;
			}
			if ((roots[1] > 0) && (roots[1] < deltaT) && (roots[1] < tMin)) {
				tMin = roots[1];
				didHit = 1;
			}
		}


		//----Set the force direction vector if appropriate
		if (didHit) {
			float xCollision = ball->centerPoint[0] + tMin * ball->velocity[0];
			float yCollision = ball->centerPoint[1] + tMin * ball->velocity[1];
			float nx = xCollision - block->startPoint[0];
			float ny = yCollision - block->startPoint[1];
			float mag = sqrt(nx * nx + ny * ny);
			if (mag > 0) {
				nx /= mag;
				ny /= mag;
			}
			forceDir[0] = nx;
			forceDir[1] = ny;
		}


		//----Second endpoint
		A = vx * vx + vy * vy;
		B = 2 * (vp1p[0] * vx + vp1p[1] * vy);
		C = vp1p[0] * vp1p[0] + vp1p[1] * vp1p[1] - r * r;
		numRoots = SolveQuadratic(A, B, C, roots);
		didHit = 0;
		if (numRoots == 1) {
			if ((roots[0] > 0) && (roots[0] < deltaT) && (roots[0] < tMin)) {
				tMin = roots[0];
				didHit = 1;
			}
		} else if (numRoots == 2) {
			if ((roots[0] > 0) && (roots[0] < deltaT) && (roots[0] < tMin)) {
				tMin = roots[0];
				didHit = 1;
			}
			if ((roots[1] > 0) && (roots[1] < deltaT) && (roots[1] < tMin)) {
				tMin = roots[1];
				didHit = 1;
			}
		}


		//----Set the force direction vector if appropriate
		if (didHit) {
			float xCollision = ball->centerPoint[0] + tMin * ball->velocity[0];
			float yCollision = ball->centerPoint[1] + tMin * ball->velocity[1];
			float nx = xCollision - block->endPoint[0];
			float ny = yCollision - block->endPoint[1];
			float mag = sqrt(nx * nx + ny * ny);
			if (mag > 0) {
				nx /= mag;
				ny /= mag;
			}
			forceDir[0] = nx;
			forceDir[1] = ny;
		}
	}


	//----Return the collision time if it was inside the time interval. Otherwise, 
	//----return -1
	if (tMin <= deltaT) return(tMin);
	else return(-1.0f);
}