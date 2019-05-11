/*
* File: Assignmment_3.pde
* Group: Group 29
* Date: 06/05/2019
* Course: COSC101 - Software Development Studio 1
* Desc: Astroids game
* Usage: Make sure to run in the processing environment and press play etc...
*/

//Array to store the asteroid objects
ArrayList<Asteroid> asteroids;
PShape spaceship;//consider changing to image
boolean sUP, sDOWN, sRIGHT, sLEFT;//control key direction
Ship ship;//ship object
// Maximum number of largest asteroids on screen... Can tie to level.
int numberAsteroids = 5;
// Asteroid hitpoints.
int asteroidLife = 3;

void setup(){
  
  size(800, 800); 
  ship = new Ship();
  smooth(); 
  // Initialize the ArrayList.
  asteroids = new ArrayList<Asteroid>();
  for (int i = 0; i < numberAsteroids; i++) { 
    asteroids.add(new Asteroid(random(width), random(height), asteroidLife, random(-5, 5), random(-5, 5)));
  }
}


void draw(){
  
  background(125);//placeholder 
  // Populate the ArrayList (backwards to avoid missing indexes) and project to the screen.
  for (int i = asteroids.size()-1; i >= 0; i--) { 
    Asteroid asteroid = asteroids.get(i);
    asteroid.move();
    asteroid.drawAsteroid();
  }
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

class Asteroid {
  //Position.
  float xPos, yPos;
  //Radius for collision detection.
  //float boundaryRadius;
  // Speed/direction on x axis.
  float xSpeed;
  // Speed/direction on y axis.
  float ySpeed; 
  //Number of times to hit.
  int hitsLeft;
  int largeAsteroid = 80;
  int mediumAsteroid = 50;
  int smallAsteroid = 20;
  // Initialise.
  Asteroid(float xPos, float yPos, int hitsLeft, float xSpeed, float ySpeed) {
    this.xPos = xPos;
    this.yPos = yPos;
    this.xSpeed = xSpeed;
    this.ySpeed = ySpeed;
    this.hitsLeft = hitsLeft;
  }

  // Draw each Asteroid to the screen at the appropriate size.
  void drawAsteroid() {
    if (hitsLeft == 3) {
      ellipse(xPos, yPos, largeAsteroid, largeAsteroid);
    } else if (hitsLeft == 2) {
      ellipse(xPos, yPos, mediumAsteroid, mediumAsteroid);
    } else if (hitsLeft == 1) {
      ellipse(xPos, yPos, smallAsteroid, smallAsteroid);
    }
  }

  // Handles asteroid movement and boundary checking.
  void move() {
    xPos += xSpeed;
    yPos += ySpeed;
    if (xPos > width) {
      xPos = 0;
    } else if (xPos < 0) {
      xPos = width;
    }
    if (yPos > height) {
      yPos = 0;
    } else if (yPos < 0) {
      yPos = height;
    }
  }

  // Returns x coordinate of Asteroid.
  float xPos() {

    return(xPos);
  }

  // Returns y coordinate of Asteroid.
  float yPos() {

    return(yPos);
  }

  // Subtracts a point from the asteroids life.
  void hitsLeft() {

    hitsLeft--;
  }

  // returns current number of hits asteroid can sustain.
  int hits() {

    return hitsLeft;
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

// Using mousePressed for now to simulate a collision.
// TODO - Merge with ship and bullet collision when completed.
void mousePressed() {
  for (int i = asteroids.size()-1; i >= 0; i--) { 
    Asteroid asteroid = asteroids.get(i);  
    // Asteroids will split when mouse is hovered directly over and clicked.
    if (circleCollision(mouseX, mouseY, 15, asteroid.xPos(), asteroid.yPos(), 25)) {
      asteroid.hitsLeft();
      // When collision occurs, kill the old asteroid and create 2 new ones at a smaller size.
      asteroids.remove(i);
      asteroids.add(new Asteroid(asteroid.xPos(), asteroid.yPos(), asteroid.hits(), random(-5, 5), random(-5, 5)));
      asteroids.add(new Asteroid(asteroid.xPos(), asteroid.yPos(), asteroid.hits(), random(-5, 5), random(-5, 5)));
    }
  }
}
