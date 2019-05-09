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

PShape spaceship;//consider changing to image
boolean sUP, sDOWN, sRIGHT, sLEFT;//control key direction
Ship ship;//ship object



class Asteroid{
  //Position
  float xPos, yPos;
  //Radius for collision detection
  float boundaryRadius;
  //Size 1,2 or 3. 1 largest 3 smallest. Hit on size 1 creates two size 2, hit on size two creates 2 size 3?
  //Link boundaryRadius to size?
  int size;
  //Track if hit, if so do not render.
  boolean hit;
  //Number of times to hit
  int hitsToRemove;
  int timesHit;
  
  
  //Initialise
  Asteroid(float xCoord, float yCoord,float collisionRadius, int asteroidSize, int toughness){
    this.xPos = xCoord;
    this.yPos = yCoord;
    this.boundaryRadius = collisionRadius/2;
    this.hit = false;
    this.size = asteroidSize;
    this.hitsToRemove = toughness;
    this.timesHit = 0;
  }
  
  void renderMe(){
    //If not hit
    if(!hit){
     //Draw image of asteroid 
     ellipse(xPos, yPos, boundaryRadius, boundaryRadius);
    }
    

    
  }
    
}


void setup(){
  
  size(800, 800);
  // Initialize the Vector arrays.
  for (int i = 0; i < asteroids.length; i++) {
    asteroids[i] = new PVector(random(width), random(height));
    asteroidDirection[i] = new PVector(random(-ranNum, ranNum), random(-ranNum, ranNum));
    
  }
  
  ship = new Ship();
  smooth(); 
}


void draw(){
  
  background(125);//placeholder  
  edgeDetect();//Shanan's
  drawAsteroids();
  ship.updatePos();
  ship.edgeCheck();
  ship.display();
  
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
  
  /*
  for(Asteroid asteroidObj : Asteroids){
    
     asteroidObj.renderMe(); 
    
  }
  */
    
  
  
  
  
  
  
  for (int i = 0; i < asteroids.length; i++) {
    asteroids[i].add(asteroidDirection[i]);
    ellipse(asteroids[i].x, asteroids[i].y, 48, 48);
    
  }
}

//feel free to modify this class structure or give advice.
class Ship {
  
  PVector location, dir;
  int moveSpeed;
  float xPos, yPos,x1,y1,x2,y2,x3,y3;
  float turnFactor;float scaleFactor;

  Ship() {
    
    //controls speed, amount of rotation and scale of ship, feel free to change
    moveSpeed=8;
    turnFactor =6;
    scaleFactor=1.5;
    //random starting coordinates
    xPos=random(0, width);
    yPos=random(0, height);
    //plan to add in acceleration, once learnt how.
    location = new PVector(xPos, yPos);
    dir = new PVector(0, -moveSpeed);
  }
  void updatePos() {
    xPos=location.x;
    yPos=location.y;

    if (sUP) {
      location.add(dir);
    } 
    if (sDOWN) {
      location.sub(dir);
    }
    if (sLEFT) {
      rotateShip(dir, radians(-turnFactor));
    }
    if (sRIGHT) {
      rotateShip(dir, radians(turnFactor));
    }
  }
  void display() {

    //triangle coordinates with centre(0,0)
    //coord's for + 90 degree rotation(HALF_PI)
    //x1=-10;y1=-15;
    //x2=-10;y2=15;
    //x3=20;y3=0;

    //same triangle, normal orientation. centre(0,0).
    x1=0;y1=-20;
    x2=-15;y2=10;
    x3=15;y3=10;
    
    pushMatrix();
    translate(location.x, location.y);
    spaceship = createShape(TRIANGLE, x1, y1, x2, y2, x3, y3);
    //spaceship.rotate(dir.heading());//for 90 degree triangle
    // rotation for normal triangle
    //add HALF_PI to offset translated rotation, may be a better way(unsure).
    spaceship.rotate(dir.heading()+HALF_PI); 
    spaceship.scale(scaleFactor);
    shape(spaceship);
    popMatrix();
    fill(0); 
    ellipse(xPos, yPos, 5, 5);//to show centre point, can be deleted
    fill(255);
  }

  void edgeCheck() {
    if (location.x < 0) { //left
      location.x = width;
    } else if (location.x > width) { //right
      location.x = 0;
    }
    if (location.y < 0) { //top
      location.y = height;
    } else if (location.y > height) { //bottom
      location.y = 0;
    }
  }
  
  //determines direction/heading
  void rotateShip(PVector vector, float angle) {
    
    float temp = dir.x;
    vector.x = dir.x*cos(angle) - vector.y*sin(angle);
    vector.y = temp*sin(angle) + vector.y*cos(angle);
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
