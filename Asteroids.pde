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
// Random asteroids.
PShape randomShape;
PShape spaceship;//consider changing to image
boolean sUP, sDOWN, sRIGHT, sLEFT, sSHOOT;//control key direction
Ship ship;//ship object
// Maximum number of largest asteroids on screen... Can tie to level.
int numberAsteroids = 3;
// Asteroid hitpoints.
int asteroidLife = 3;
// Length of the shapes array
int shapeLength = numberAsteroids * 3;
PShape[] shapes = new PShape[shapeLength];
//  0 = Start screen, 1 = gameplay, 2 = Game Over screen.
int gameScreen = 0;
//configuration setting
float bulletMaxDistance = 250;

void setup() {
  frameRate(60);
  size(800, 800);
  background(0);
  ship = new Ship();
  smooth(); 
  // Generate an array of random asteroid shapes.
  drawShapes();
  for (int i = 0; i < shapes.length; i++) {
    shape(shapes[i], random(width), random(height), 100, 100);
  }
  // Initialize the ArrayList.
  asteroids = new ArrayList<Asteroid>();
  for (int i = 0; i < numberAsteroids; i++) { 
    asteroids.add(new Asteroid(random(width), random(height), asteroidLife, random(-2, 2), random(-2, 2)));
  }

  projectiles = new ArrayList<Projectile>();
}

void draw() {

if (gameScreen == 0) {
    initScreen();
  } else if (gameScreen == 1) {
    gameScreen();
  } else if (gameScreen == 2) {
    gameOverScreen();
  }
}

//TO BE MODIFIED ONCE EDGE OF MAP DETECTION FUNCTION IS REFACTORED.
/*
Function Purpose: To remove projectiles from the array if they go beyond the bounds of the screen.
 Called from: **
 Inputs: floats representing the x & y coordinates of two objects (x,yPos1 & x,yPos2) and the detection radius of each object.
 */
void updateAndDrawProjectiles() {

  for (int i = projectiles.size()-1; i >= 0; i--) { 
    Projectile bullet = projectiles.get(i);

    PVector checkedLocation = mapEdgeWrap(bullet.blocation, bullet.radius);
    bullet.blocation = checkedLocation;

    if (bullet.distanceTravelled >= bulletMaxDistance) {
      projectiles.remove(i);
    } else {
      bullet.move();
      bullet.display();
    }
  }
}


/*
Function Purpose: To detect collisions between two objects using circle collision detection.
 Called from: **
 Inputs: floats representing the x & y coordinates of two objects (x,yPos1 & x,yPos2) and the detection radius of each object.
 */
boolean circleCollision(float xPos1, float yPos1, float radOne, float xPos2, float yPos2, float radTwo) {

  if (dist(xPos1, yPos1, xPos2, yPos2) < radOne + radTwo) {
    //There is a collision
    return true;
  }
  return false;
}

PVector mapEdgeWrap(PVector object, float radius) {
  if (object.x < -radius) { //left
    object.x = width+radius;
  } else if (object.x > width+radius) { //right
    object.x = -radius;
  }
  if (object.y <= -radius*2) { //top
    object.y = height;
  } else if (object.y > height) { //bottom
    object.y = -radius*2;
  }
  return object;
}

//feel free to modify this class structure or give advice.
class Ship {

  PVector location, dir, noseLocation, acceleration, velocity;
  int bulletSpeed; //changed from moveSpeed
  float xPos, yPos, noseX, noseY;
  float radius, x1, y1, x2, y2, x3, y3, x4, y4, y5; 
  float turnFactor, topSpeed, heading;
  float resistance, mass, thrustFactor;

  Ship() {
    //controls speed, amount of rotation and scale of ship, feel free to change
    //down to thrustFact can all be modified in our settings class once that's made
    bulletSpeed=int(topSpeed);//might be worth moving to bullet class, no longer used on ship.
    resistance=0.995;//lower = more resistance
    mass = 1;
    turnFactor =6;//turning tightness
    topSpeed = 6;
    radius =30;//size of ship and collision detection radius
    thrustFactor=0.15;//propelling

    //vertex based on isosceles triangle.
    x1 =0; 
    y1=-radius;//top
    x2=-radius; 
    y2=radius;//bottom left
    x3=radius; 
    y3=radius;//bottom right
    x4=0; 
    y4=radius/2.0; //bottom center
    y5=(y3+y4)/2.0;//coord for flame

    //random starting coordinates
    xPos=random(radius, width-radius);
    yPos=random(0, height-(radius*2));
    //initialise vectors
    acceleration = new PVector(0, 0);
    velocity = new PVector(0, 0);
    location = new PVector(xPos, yPos);
    noseLocation = new PVector(location.x, location.y);
    dir = new PVector(0, -1);
  }
  void updatePos() {
    xPos=location.x;
    yPos=location.y;
    heading = dir.heading();

    velocity.add(acceleration);
    velocity.mult(resistance);
    velocity.limit(topSpeed);
    location.add(velocity);
    acceleration.mult(0);//reset acceleration to 0 each frame
    noseLocation.set(noseX, noseY);
    if (sUP) {
      propel();
    } 
    if (sDOWN) {
      propel();
    }
    if (sLEFT) {
      rotateShip(dir, radians(-turnFactor));
      //noseLocation.add(dir);
    }
    if (sRIGHT) {
      rotateShip(dir, radians(turnFactor));
      //noseLocation.sub(dir);
    }
    if (sSHOOT) {
      shoot();
      sSHOOT = false;
    }
  }
  //newton's law: acceleration = force/mass
  void applyForce(PVector force) {
    PVector temp = force.copy();
    //PVector temp =dir.copy(); //add's force to turn, but without resistance at the moment.
    force.div(mass);
    acceleration.add(temp);
  }
  void propel() {
    PVector force = new PVector(cos(heading), sin(heading));
    if (sUP) {
      force.mult(thrustFactor);//propelling
    }
    if (sDOWN) {
      force.mult(-thrustFactor);//reverse
    }
    applyForce(force);
  }
  void display() {
    pushMatrix();
    translate(location.x, location.y+radius);
    rotate(heading+HALF_PI);
    fill(175);
    stroke(175);
    //getting a bit cluttered - maybe make into drawShip func and call from here
    beginShape();
    vertex(x1, y1);//top
    vertex(x2, y2);//bottom left
    vertex(x4, y4);//bottom middle
    vertex(x3, y3);//bottom right
    endShape(CLOSE);
    if (sUP) {//if propelling show exhaust flame
      //strokeWeight(4);
      stroke(255); //flame colour
      //noFill();
      beginShape();
      vertex(0, radius/2.0);
      vertex(x2+radius/2.0, y5);
      vertex(x1, y3+radius/2.0);//peak of flame
      vertex(x3-radius/2.0, y5);
      endShape(CLOSE);
    }
    //coordinates for nose outside of matrix
    noseX=screenX(0, y1);
    noseY=screenY(0, y1);
    popMatrix();
    fill(255);
    stroke(255);
    //ellipse(noseLocation.x,noseLocation.y,5,5);//ship nose location
    //ellipse(location.x, location.y+shipRad, 5, 5);//ship center of rotation
  }

  void edgeCheck() {
    PVector checkedLocation = mapEdgeWrap(location, radius);
    location = checkedLocation;
  }

  //determines direction/heading
  void rotateShip(PVector vector, float angle) {
    float temp = dir.x;
    vector.x = dir.x*cos(angle) - vector.y*sin(angle);
    vector.y = temp*sin(angle) + vector.y*cos(angle);
  }
  //Adds a new projectile
  void shoot() {

    projectiles.add(new Projectile(dir, noseLocation, bulletSpeed, bulletMaxDistance));
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
  int largeAsteroid = 100;
  int mediumAsteroid = 70;
  int smallAsteroid = 40;
  // Initialise.
  Asteroid(float xPos, float yPos, int hitsLeft, float xSpeed, float ySpeed) {
    this.xPos = xPos;
    this.yPos = yPos;
    this.xSpeed = xSpeed;
    this.ySpeed = ySpeed;
    this.hitsLeft = hitsLeft;
  }

  // Draw each Asteroid to the screen at the appropriate size.
  void drawAsteroid(PShape shapes) {
    if (hitsLeft == 3) {
      shape(shapes, xPos, yPos, largeAsteroid, largeAsteroid);
    } else if (hitsLeft == 2) {
      shape(shapes, xPos, yPos, mediumAsteroid, mediumAsteroid);
    } else if (hitsLeft == 1) {
      shape(shapes, xPos, yPos, smallAsteroid, smallAsteroid);
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
class Projectile {
  PVector blocation = new PVector(), direction = new PVector();
  float speed, distanceTravelled, maxDistance;
  boolean visible;
  float radius;

  Projectile(PVector shipDirection, PVector shipLocation, float spd, float maxDistance) {
    this.speed = spd;
    this.visible = true;
    this.blocation = blocation.set(shipLocation.x, shipLocation.y);
    this.direction = direction.set(shipDirection.x * 4, shipDirection.y * 4);
    this.radius = 5;
    this.maxDistance = maxDistance;
    this.distanceTravelled = 0;
  }


  //Update position of projectile
  void move() {
    distanceTravelled += 1;
    blocation.add(direction);
  }

  void display() {
    //Draw bullet.
    ellipse(blocation.x, blocation.y, 5, 5);
  }
}

// Fill random shapes array.
void drawShapes() {
  for (int i = 0; i < shapes.length; i++) {
    noFill();
    stroke(255);
    randomShape = createShape();
    randomShape.beginShape();
    randomShape.vertex(50, 50);
    randomShape.vertex(random(50, 70), random(60, 80));
    randomShape.vertex(random(80, 100), random(50, 50));
    randomShape.vertex(random(90, 110), random(70, 90));
    randomShape.vertex(random(75, 95), random(80, 100));
    randomShape.vertex(random(75, 95), random(100, 120));
    randomShape.vertex(random(55, 75), random(100, 110));
    randomShape.vertex(random(25, 50), random(80, 100));
    randomShape.vertex(random(30, 50), random(70, 90));
    randomShape.vertex(random(20, 30), random(50, 60));
    randomShape.vertex(50, 50);
    randomShape.endShape(CLOSE);
    shapes[i] = randomShape;
  }
}

//Detect collisions between Ship + Asteroids and asteroids + bullets.
void detectCollisions() {
  for (int i = asteroids.size()-1; i >= 0; i--) { 
    Asteroid asteroid = asteroids.get(i);  
    // Check to see if the player's ship is hit first - game over
    if (circleCollision(ship.xPos, ship.yPos, ship.radius, asteroid.xPos(), asteroid.yPos(), asteroid.radius)) {
      println("Game over");
      gameOver();
      setup();
    }

    for (int j=projectiles.size()-1; j >= 0; j--) {
      Projectile bullet = projectiles.get(j);
      if (!bullet.visible) {
        continue;
      } else {
        if (circleCollision(bullet.blocation.x, bullet.blocation.y, bullet.radius, asteroid.xPos(), asteroid.yPos(), asteroid.radius)) {
          projectiles.remove(j);
          asteroid.hitsLeft();
          // When collision occurs, kill the old asteroid and create 2 new ones at a smaller size.
          asteroids.remove(i);
          if (asteroid.hits() >0) {
            asteroids.add(new Asteroid(asteroid.xPos(), asteroid.yPos(), asteroid.hits(), random(-2, 2), random(-2, 2)));
            asteroids.add(new Asteroid(asteroid.xPos(), asteroid.yPos(), asteroid.hits(), random(-2, 2), random(-2, 2)));
          }
        }
      }
    }
  }
}

void initScreen() {

  textSize(100);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("Asteroids", width/2, 150); 
  textSize(50);
  fill(0, 102, 153);
  textAlign(CENTER);
  text("Press any key to start game.", width/2, 450); 
  textSize(25);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("W, A, S, D keys for movement, L/SPACEBAR to shoot.", width/2, 750);
}

void gameOverScreen() {

  textSize(100);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("Game Over", width/2, 150); 
  textSize(25);
  fill(0, 102, 153);
  textAlign(CENTER);
  text("Click mouse to start a new game.", width/2, 450);
}

void startGame(){
  gameScreen = 1;
}

void gameOver(){
  
  gameScreen = 2;
}

void restart(){
  
  gameScreen = 0;
}
  
void gameScreen(){
    background(0);// Set to black as per the original game.
    // Populate the ArrayList (backwards to avoid missing indexes) and project to the screen.
    for (int i = asteroids.size()-1; i >= 0; i--) { 
      Asteroid asteroid = asteroids.get(i);
      asteroid.move();
      asteroid.drawAsteroid(shapes[i]);
    }
    detectCollisions();
    ship.updatePos();
    ship.edgeCheck();
    ship.display();
    updateAndDrawProjectiles();
}

void mousePressed() {
  // if we are on the initial screen when clicked, start the game 
  if (gameScreen == 0) { 
    gameScreen = 1;
  }
  if (gameScreen == 2) {
    gameScreen = 1;
  }
}

void keyPressed() {
  if (gameScreen == 0) { 
    gameScreen = 1;
  }
  //added arrow keys for movement
  if (key== 'w'|| keyCode==UP) {
    sUP=true;
  }
  if (key=='s' || keyCode==DOWN) {
    sDOWN=true;
  }
  if (key=='d' || keyCode==RIGHT) {
    sRIGHT=true;
  }
  if (key=='a'|| keyCode==LEFT) {
    sLEFT=true;
  }
}

void keyReleased() {
  if (key== 'w'||keyCode==UP) {
    sUP=false;
  }
  if (key=='s'|| keyCode==DOWN) {
    sDOWN=false;
  }
  if (key=='d'||keyCode==RIGHT) {
    sRIGHT=false;
  }
  if (key=='a'||keyCode==LEFT) {
    sLEFT=false;
  }
  if (key=='l'||key==' ') {//added spacebar for shooting
    sSHOOT=true;
  }
}
