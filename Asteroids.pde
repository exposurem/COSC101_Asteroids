/*
* File: Assignmment_3.pde
* Group: Group 29
* Date: 06/05/2019
* Course: COSC101 - Software Development Studio 1
* Desc: Astroids game
* Usage: Make sure to run in the processing environment and press play etc...
*/

PVector[] asteroids = new PVector[6];
PVector[] asteroidDirection = new PVector[6];
int ranNum = 5;


//Array to store the asteroid objects
ArrayList<Asteroid> Asteroids = new ArrayList<Asteroid>();
//ArrayList and class for projectiles or just use two arrays?



class Asteroid{
  
  
}


void setup(){
  
  size(800, 800);
  // Initialize the Vector arrays.
  for (int i = 0; i < asteroids.length; i++) {
    asteroids[i] = new PVector(random(width), random(height));
    asteroidDirection[i] = new PVector(random(-ranNum, ranNum), random(-ranNum, ranNum));
    
  }  
}


void draw(){
  
  background(0);  
  edgeDetect();
  drawAsteroids();
  
}

/*
Function Purpose: To detect collisions between two objects using circle collision detection.
Called from: **
Inputs: floats representing the x & y coordinates of two objects (x,yPos1 & x,yPos2) and the detection radius of each object.
*/
boolean circleCollision(float xPos1, float yPos1,float radOne, float xPos2, float yPos2, float radTwo){
  
  if(dist(xPos1,yPos1,xPos2,yPos2) < radOne + radTwo){
    //There is a collision
    return true;
  }
  return false;
}

/*
* Function: edgeDetect()
* Parameters: None
* Returns: Void
* Desc: Allows asteroids to wrap around the screen when they reach the edge.
*/

void edgeDetect(){
  
  for (int i = 0; i < asteroids.length; i++) {
    if (asteroids[i].x > width){
    asteroids[i].x = 0;
    } else if (asteroids[i].x < 0){
      asteroids[i].x = width;
    }
    if (asteroids[i].y > height){
    asteroids[i].y = 0;
    } else if (asteroids[i].y < 0){
      asteroids[i].y = height;
    }
          
    }
  }
  
/*
* Function: drawAsteroids()
* Parameters: None
* Returns: Void
* Desc: Populates the screen with asteroids that have a random direction and speed.
*/

void drawAsteroids(){
  
  for (int i = 0; i < asteroids.length; i++) {
    asteroids[i].add(asteroidDirection[i]);
    ellipse(asteroids[i].x, asteroids[i].y, 48, 48);
    
  }
}
