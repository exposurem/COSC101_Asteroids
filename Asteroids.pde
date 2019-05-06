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

float x1, y1, x2, y2, x3, y3, triXCenter, triYCenter, triSize; //triangle PShape variables
PShape ship; //consider changing to image
float speed;
boolean sUP=false, sDOWN=false, sRIGHT = false, sLEFT=false;



class Asteroid{
  
  
}


void setup(){
  
  size(800, 800);
  // Initialize the Vector arrays.
  for (int i = 0; i < asteroids.length; i++) {
    asteroids[i] = new PVector(random(width), random(height));
    asteroidDirection[i] = new PVector(random(-ranNum, ranNum), random(-ranNum, ranNum));
    
  }
  
  speed=2; //can be changed
  triSize=5; //can be changed

  //random starting coordinates
  triXCenter=random((0+triSize), (width-triSize));
  triYCenter=random((0+triSize), (height-triSize));  
}


void draw(){
  
  background(125);//placeholder  
  edgeDetect();//Shanan's
  drawAsteroids();
  shipEdgeCheck();//Daniel's
  drawShip();
  moveShip();
  
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
void drawShip() {
  //top corner
  x1=triXCenter;
  y1=triYCenter-triSize;
  //bottom left corner
  x2=triXCenter-triSize;
  y2=triYCenter+triSize;
  //bottom right corner
  x3=triXCenter+triSize;
  y3=triYCenter+triSize;

  ship = createShape(TRIANGLE, x1, y1, x2, y2, x3, y3);
  shape(ship);
}

void shipEdgeCheck() {
  //Placeholder edge detection 
  //may need to be changed/replaced once ship is rotating or if image used instead of PShape,
  //will act like a radius from center point which may cause some issues with 
  //triangular shaped ship.

  if (triXCenter+abs(triSize)<0) {//left side
    triXCenter=width+triSize;
  }else if (triXCenter-abs(triSize)>width) {//right side
    triXCenter=0-triSize;
  }else if (triYCenter+abs(triSize)<0) {//top side
    triYCenter=height+triSize;
  }else if (triYCenter-abs(triSize)>height) {//bottom side
    triYCenter=0-triSize;
  }
}

void moveShip() {
  if (sUP) {
    triYCenter-=speed;
  }
  if (sDOWN) {
    triYCenter+=speed;
  }
  if (sRIGHT) {
    triXCenter+=speed;
  }
  if (sLEFT) {
    triXCenter-=speed;
  }
}

void keyPressed() {
  //direction movement
  if (key== 'w') {
    sUP=true;
  }
  if (key=='s') {
    sDOWN=true;
  }
  if (key=='d') {
    sRIGHT=true;
  }
  if (key=='a') {
    sLEFT=true;
  }
}

void keyReleased() {
  if (key== 'w') {
    sUP=false;
  }
  if (key=='s') {
    sDOWN=false;
  }
  if (key=='d') {
    sRIGHT=false;
  }
  if (key=='a') {
    sLEFT=false;
  }
}
