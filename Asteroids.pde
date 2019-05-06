
//Array to store the asteroid objects
ArrayList<Asteroid> Asteroids = new ArrayList<Asteroid>();
//ArrayList and class for projectiles or just use two arrays?



class Asteroid{
  
  
}


void setup(){
  
  
}


void draw(){
  
  
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
