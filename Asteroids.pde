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
ArrayList<Projectile> projectiles;
PShape spaceship;//consider changing to image
boolean sUP, sDOWN, sRIGHT, sLEFT, sSHOOT;//control key direction
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
  
  projectiles = new ArrayList<Projectile>();
}


void draw(){
  
  background(125);//placeholder 
  // Populate the ArrayList (backwards to avoid missing indexes) and project to the screen.

  for (int i = asteroids.size()-1; i >= 0; i--) { 
    Asteroid asteroid = asteroids.get(i);
    asteroid.move();
    asteroid.drawAsteroid();
  }
  detectCollisions();
  ship.updatePos();
  ship.edgeCheck();
  ship.display();
  updateAndDrawProjectiles();
  
}


//TO BE MODIFIED ONCE EDGE OF MAP DETECTION FUNCTION IS REFACTORED.
/*
Function Purpose: To remove projectiles from the array if they go beyond the bounds of the screen.
Called from: **
Inputs: floats representing the x & y coordinates of two objects (x,yPos1 & x,yPos2) and the detection radius of each object.
*/
void updateAndDrawProjectiles(){

  for (int i = projectiles.size()-1; i >= 0; i--) { 
  Projectile bullets = projectiles.get(i);  

  if (bullets.blocation.x >= width  || bullets.blocation.x <= 0 || bullets.blocation.y >= height || bullets.blocation.y <=0 ) {
    println("-----");
    println("---In if--");
    println(bullets.visible);
    println(bullets.blocation.x);
    println(bullets.blocation.y);
    println("----------------");
    projectiles.remove(i);
  }
  else{
    bullets.move();
    bullets.display();
   
    }
  }
  
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
  
  PVector location, dir, noseLocation;
  int moveSpeed;
  float xPos, yPos,x1,y1,x2,y2,x3,y3,yNoseOffset,radius;
  float turnFactor;float scaleFactor;

  Ship() {
    
    //controls speed, amount of rotation and scale of ship, feel free to change
    moveSpeed=8;
    turnFactor =6;
    scaleFactor=1.5;
    //same triangle, normal orientation. centre(0,0).
    x1=0;y1=-20;
    x2=-15;y2=10;
    x3=15;y3=10;
    //Collision detection radius.
    radius = (abs(x2) + abs(x3)) /2;
    yNoseOffset = -27;
    //random starting coordinates
    xPos=random(0, width);
    yPos=random(0, height);
    //plan to add in acceleration, once learnt how.
    location = new PVector(xPos, yPos);
    noseLocation = new PVector(location.x,location.y-yNoseOffset);
    dir = new PVector(0, -moveSpeed);
  }
  void updatePos() {
    xPos=location.x;
    yPos=location.y;

    if (sUP) {
      location.add(dir);
      noseLocation.add(dir);
    } 
    if (sDOWN) {
      location.sub(dir);
      noseLocation.sub(dir);
    }
    if (sLEFT) {
      rotateShip(dir, radians(-turnFactor));
      noseLocation.add(dir);
    }
    if (sRIGHT) {
      rotateShip(dir, radians(turnFactor));
      noseLocation.sub(dir);
    }
    if (sSHOOT){
      shoot();
      sSHOOT = false;
       
    }
    //println(noseLocation.x);
  }
  void display() {

    //triangle coordinates with centre(0,0)
    //coord's for + 90 degree rotation(HALF_PI)
    //x1=-10;y1=-15;
    //x2=-10;y2=15;
    //x3=20;y3=0;


    
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
 //<>//
  }
  //Adds a new projectile
  void shoot(){
    
    projectiles.add(new Projectile(dir,location,moveSpeed));
    
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
  float radius = 25;
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


//Change hardcoded radius, solve and clean up class once issue it fixed.
class Projectile{
  PVector blocation = new PVector(),direction = new PVector();
  float speed;
  boolean visible;
  float radius;
  
  Projectile(PVector shipDirection, PVector shipLocation, float spd){
    this.speed = spd;
    this.visible = true;
    this.blocation = blocation.set(shipLocation.x,shipLocation.y);
    this.direction = direction.set(shipDirection.x,shipDirection.y);
    this.radius = 5;
  }
  
  
  //Update position of projectile
  void move(){
    blocation.add(direction); 
  }
  
  void display(){
  //Draw bullet.
  ellipse(blocation.x, blocation.y, 5, 5);
    
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
   if (key=='l') {
    sSHOOT=true;
  }
}

//Detect collisions between Ship + Asteroids and asteroids + bullets.
void detectCollisions() {
  for (int i = asteroids.size()-1; i >= 0; i--) { 
    Asteroid asteroid = asteroids.get(i);  
    // Check to see if the player's ship is hit first - game over
    if (circleCollision(ship.xPos,ship.yPos,ship.radius,asteroid.xPos(), asteroid.yPos(), asteroid.radius)){
      //println("Game over");
    }
    
    for(int j=projectiles.size()-1; j >= 0;j--){
      Projectile bullet = projectiles.get(j);
      if(!bullet.visible){
         continue; 
      }
      else{
        if (circleCollision(bullet.blocation.x, bullet.blocation.y, bullet.radius, asteroid.xPos(), asteroid.yPos(), asteroid.radius)) {
        projectiles.remove(j);
        asteroid.hitsLeft();
        // When collision occurs, kill the old asteroid and create 2 new ones at a smaller size.
        asteroids.remove(i);
        if(asteroid.hits() >0){
          asteroids.add(new Asteroid(asteroid.xPos(), asteroid.yPos(), asteroid.hits(), random(-5, 5), random(-5, 5)));
          asteroids.add(new Asteroid(asteroid.xPos(), asteroid.yPos(), asteroid.hits(), random(-5, 5), random(-5, 5)));
        }

        }
      }

    }
    
  }
}
