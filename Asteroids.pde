/*
* File: Assignmment_3.pde
 * Group: Group 29
 * Date: 06/05/2019
 * Course: COSC101 - Software Development Studio 1
 * Desc: Astroids game
 * Usage: Make sure to run in the processing environment, have the sound library installed and press play etc...
 *
 Resource Credits
 Asteroid explosion - https://freesound.org/people/runningmind/sounds/387857/ 
 Shooting sound - https://freesound.org/people/alphatrooper18/sounds/362420/
 
 */

import processing.sound.*;
//Array to store the asteroid objects
ArrayList<Asteroid> asteroids;
ArrayList<Projectile> projectiles;
// Random asteroids.
PShape randomShape;
PShape spaceship;//consider changing to image
boolean sUP, sDOWN, sRIGHT, sLEFT, sSHOOT;//control key direction
Ship ship;//ship object
boolean paused;
int level = 1;
// Number of asteroids destroyed.
int killCount = 0;
// Maximum number of largest asteroids on screen... Can tie to level.
float asteroidSpeed = 1;
int numberAsteroids = 1;
// Asteroid hitpoints.
int asteroidLife = 3;
// Length of the shapes array
int shapeLength = 10;
PShape[] shapes = new PShape[shapeLength];
//  0 = Start screen, 1 = gameplay, 2 = Game Over screen.
int gameScreen = 0;
//configuration setting
float bulletMaxDistance;
SoundFile explosionSound;
SoundFile shootSound;

//Setting up outside of the setup() due to call from gameover. May need to split up things that
//need to be reset between games in another function, and leave setup for the things that are done once.

ScoreBoard aScoreBoard = new ScoreBoard(400, 20); //score board object

void setup() {
  frameRate(60);
  size(800, 800);
  ship = new Ship();
  explosionSound = new SoundFile(this, "explosion.wav");
  shootSound = new SoundFile(this, "shooting.wav");
  smooth(); 
  // Generate an array of random asteroid shapes.
  drawShapes();
  for (int i = 0; i < shapes.length; i++) {
    shape(shapes[i], random(width), random(height), 100, 100);
  }
  // Initialize the ArrayList.
  asteroids = new ArrayList<Asteroid>();
  for (int i = 0; i < numberAsteroids; i++) { 
    createAsteroid(asteroidLife);
  }

  projectiles = new ArrayList<Projectile>();
  bulletMaxDistance = height;//move to settings class when made
  background(0);
}

void draw() {

  if (gameScreen == 0) {
    initScreen();
  } else if (gameScreen == 1) {
    gameScreen();
  } else if (gameScreen == 2) {
    levelScreen();
  } else if (gameScreen == 3) {
    gameOverScreen();
  }
    else if (gameScreen == 4) {
    gamePauseScreen(); 
    
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

void createAsteroid(int asteroidLife){
  PVector location = new PVector(random(random(0, 100)), random(width-100, width), random(height));
  PVector velocity = new PVector(random(-2, 2), random(-2, 2));
  int shape = chooseShape(shapeLength);
  asteroids.add(new Asteroid(location, velocity, asteroidLife, shape));
  
}

void splitAsteroid(Asteroid asteroid ){
  PVector location = asteroid.location;
  PVector velocityOne = new PVector(random(-asteroidSpeed, asteroidSpeed),random(-asteroidSpeed, asteroidSpeed));
  PVector velocityTwo = new PVector(random(-asteroidSpeed, asteroidSpeed),random(-asteroidSpeed, asteroidSpeed));
  int shapeOne = chooseShape(shapeLength);
  int shapeTwo = chooseShape(shapeLength);
  asteroids.add(new Asteroid(location, velocityOne, asteroid.hitsLeft, shapeOne));
  asteroids.add(new Asteroid(location, velocityTwo, asteroid.hitsLeft, shapeTwo));
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

int chooseShape(int maxNumber) {
  int number = int(random(0, maxNumber));

  return number;
}

//feel free to modify this class structure or give advice.
class Ship {

  PVector location, direction, noseLocation, acceleration, velocity;
  float xPos, yPos, noseX, noseY, radius; 
  float turnFactor, heading; 
  float resistance, mass, thrustFactor, maxSpeed;

  Ship() {
    //controls speed, amount of rotation and scale of ship, feel free to change
    //down to thrustFact can all be modified in our settings class once that's made
    resistance=0.99;//lower = more resistance
    mass = 1;
    turnFactor =6;//turning tightness
    maxSpeed = 9;
    radius =25;//size of ship and collision detection radius
    thrustFactor=0.15;//propelling

    xPos = width/2.0; 
    yPos = height/2.0;
    //initialise vectors
    acceleration = new PVector(0, 0);
    velocity = new PVector(0, 0);
    location = new PVector(xPos, yPos+radius);
    noseLocation = new PVector(location.x, location.y-radius);
    direction = new PVector(0, -1);
  }
  void updatePos() {
    xPos=location.x;
    yPos=location.y;
    heading = direction.heading();

    velocity.add(acceleration);
    velocity.mult(resistance);
    velocity.limit(maxSpeed);
    location.add(velocity);
    acceleration.set(0, 0);//reset acceleration so it doesn't stack
    noseLocation.set(noseX, noseY);
    if (sUP) {
      propel();
    } 
    if (sDOWN) {
      propel();
    }
    if (sLEFT) {
      rotateShip(direction, radians(-turnFactor), heading);
    }
    if (sRIGHT) {
      rotateShip(direction, radians(turnFactor), heading);
    }
    if (sSHOOT) {
      shoot();
      sSHOOT = false;
    }
  }

  void display() {
    pushMatrix();
    translate(location.x, location.y);
    rotate(heading+HALF_PI);
    noFill();
    drawShip();
    if (sUP) {//if propelling show exhaust flame
      drawExhaust();
    }
    //coordinates for nose outside of matrix
    noseX=screenX(0, -radius);
    noseY=screenY(0, -radius);
    popMatrix();
    stroke(255);
    //ellipse(noseLocation.x,noseLocation.y,5,5);//ship nose location
    //ellipse(location.x, location.y, 5, 5);//ship center of rotation
  }

  void drawShip() {
    stroke(255);
    beginShape();
    vertex(0, -radius);//top
    vertex(-radius, radius);//bottom left
    vertex(0, radius/2.0);//bottom middle
    vertex(radius, radius);//bottom right
    endShape(CLOSE);
  }

  void drawExhaust() {
    //strokeWeight(3);
    stroke(255); //flame colour
    beginShape();
    vertex(0, radius/2.0);
    vertex(-radius/2.0, radius*0.75);
    vertex(0, radius*1.5);//peak of flame
    vertex(radius/2.0, radius*0.75);
    endShape(CLOSE);
  }

  void propel() {
    PVector thrust = new PVector(cos(heading), sin(heading));
    if (sUP) {
      thrust.setMag(thrustFactor);//accelerate
    }
    if (sDOWN) {
      thrust.setMag(-thrustFactor);//reverse
    }
    acceleration.div(mass);
    acceleration.add(thrust);
  }

  void edgeCheck() {
    PVector checkedLocation = mapEdgeWrap(location, radius);
    location = checkedLocation;
  }

  //determines direction/heading
  void rotateShip(PVector vector, float heading, float turnFactor) {
    heading +=turnFactor;
    vector.x = vector.mag() * cos(heading);
    vector.y = vector.mag() * sin(heading);
  }

  //Adds a new projectile
  void shoot() {
    //Normal speed = 6, level 2 = 5, level >=3 = 4. Tie to difficulty game settings.
    shootSound.play();
    projectiles.add(new Projectile(direction, noseLocation, 6, bulletMaxDistance, velocity.mag(), heading));
  }
}
// Fill random shapes array.
void drawShapes() {
  for (int i = 0; i < shapes.length; i++) {
    noFill();
    stroke(255);
    shapeMode(CENTER);
    randomShape = createShape();
    randomShape.beginShape();
    randomShape.vertex(50, 50);
    randomShape.vertex(random(40, 60), random(0, 20));
    randomShape.vertex(random(80, 100), random(5, 25));
    randomShape.vertex(random(70, 90), random(30, 40));
    randomShape.vertex(random(90, 110), random(25, 45));
    randomShape.vertex(random(70, 90), random(70, 90));
    randomShape.vertex(random(50, 50), random(65, 75));
    randomShape.vertex(random(15, 25), random(70, 90));
    randomShape.vertex(random(20, 40), random(40, 60));
    randomShape.vertex(random(0, 20), random(30, 40));
    randomShape.vertex(random(15, 35), random(5, 25));
    randomShape.endShape(CLOSE);
    shapes[i] = randomShape;
  }
}

class Asteroid {
  PVector location;
  PVector velocity;
  //Number of times to hit.
  int hitsLeft;
  float radius = 50;
  int shape;
  // Initialise.
  Asteroid(PVector location, PVector velocity, int hitsLeft, int shape) {
    this.location = location;
    this.velocity = velocity;
    this.hitsLeft = hitsLeft;
    this.shape = shape;
  }

  // Draw each Asteroid to the screen at the appropriate size.
  void drawAsteroid(PShape shapes) {
    if (hitsLeft == 3) {
      shape(shapes, location.x, location.y, radius*3, radius*3);
    } else if (hitsLeft == 2) {
      shape(shapes, location.x, location.y, radius*2, radius*2);
    } else if (hitsLeft == 1) {
      shape(shapes, location.x, location.y, radius, radius);
    }
  }

  // Handles asteroid movement and boundary checking.
  void move() {
    location.add(velocity);    
    if (location.x > width) {
      location.x = 0;
    } else if (location.x < 0) {
      location.x = width;
    }
    if (location.y > height) {
      location.y = 0;
    } else if (location.y < 0) {
      location.y = height;
    }
  }

  // Returns x coordinate of Asteroid.
  float xPos() {
    return location.x;
  }

  // Returns y coordinate of Asteroid.
  float yPos() {
    return location.y;
  }

  // Subtracts a point from the asteroids life.
  void hitsLeft() {
    hitsLeft--;
  }

  float aRadius() {
    if (hitsLeft == 3) {
      return (radius*3)/2;
    } else if (hitsLeft == 2) {
      return (radius*2)/2;
    } else return radius/2;
  }

  // returns current number of hits asteroid can sustain.
  int hits() {
    return hitsLeft;
  }
}

//Change hardcoded radius, solve and clean up class once issue it fixed.
//Normal speed = 6, level 2 = 5, level >=3 = 4.
class Projectile {
  PVector blocation = new PVector(), direction = new PVector(), velocity;
  float  distanceTravelled, maxDistance;
  int speed;
  boolean visible;
  float radius;
  float magnitude;
  float heading;

  Projectile(PVector shipDirection, PVector shipLocation, int speed, float maxDistance, float mag, float heading) {
    this.speed = speed;
    this.visible = true;
    this.blocation = blocation.set(shipLocation.x, shipLocation.y);
    this.direction = direction.set(shipDirection.x * speed, shipDirection.y * speed);
    this.radius = 5;
    this.maxDistance = maxDistance;
    this.distanceTravelled = 0;
    this.velocity = new PVector();
    this.magnitude = mag;
    this.heading = heading;
  }


  //Update position of projectile
  void move() {
    PVector tempDir = new PVector(cos(heading)*speed, sin(heading)*speed);

    velocity.setMag(magnitude);//should be dynamic, won't exceed ship.maxSpeed
    velocity.add(tempDir);//add's a constant of bullet speed
    blocation.add(velocity);//ship still: (speed + 0), moving: (speed+current mag)
    distanceTravelled +=velocity.mag();
  }

  void display() {
    //Draw bullet.
    ellipse(blocation.x, blocation.y, 5, 5);
  }
}

class ScoreBoard {
  int score;
  float xPos;
  float yPos;

  ScoreBoard(float xPos, float yPos) {
    this.score = 0; 
    this.xPos = xPos;
    this.yPos = yPos;
  }
  //Method to update the score, largest asteroid worth the least, smallest the most. Based off hits left attribute.
  void update(int hitsLeft) {
    switch(hitsLeft) {
    case 1:
      score += 300;
      break;
    case 2:
      score += 180;
      break;
    case 3: 
      score += 100;
      break;
    }
  }

  void reset() {
    score = 0;
  }

  void drawMe() {
    textSize(20);
    fill(255, 255, 255);
    textAlign(CENTER);
    text("Score: " + aScoreBoard.score, aScoreBoard.xPos, aScoreBoard.yPos);
  }
}

//Detect collisions between Ship + Asteroids and asteroids + bullets.
void detectCollisions() {
  for (int i = asteroids.size()-1; i >= 0; i--) {
    Asteroid asteroid = asteroids.get(i);
    noFill();
    stroke(255, 0, 0);
    // Check to see if the player's ship is hit first - game over
    if (circleCollision(ship.xPos, ship.yPos, ship.radius, asteroid.xPos(), asteroid.yPos(), asteroid.aRadius())) {
      gameOver();
      break;
    }

    for (int j=projectiles.size()-1; j >= 0; j--) {
      Projectile bullet = projectiles.get(j);
      noFill();
      stroke(255, 0, 0);
      if (circleCollision(bullet.blocation.x, bullet.blocation.y, bullet.radius, asteroid.xPos(), asteroid.yPos(), asteroid.aRadius())) {
        //Call functions and perform actions to handle the collision event
        handleAsteroidCollision(asteroid, i, j);
        //Check if all of the asteroids have been destroyed.
        if (killCount == numberAsteroids*7) {
          levelUp();
          nextLevel();
          killCount = 0;

          break;
        }
        //Split into new asteroids
        if (asteroid.hits() >0) {
          splitAsteroid(asteroid);
          break;
        }
      }
    }
  }
}

void handleAsteroidCollision(Asteroid asteroid,int asteroidId, int projectileId){
  explosionSound.play();
  aScoreBoard.update(asteroid.hitsLeft);
  projectiles.remove(projectileId);
  asteroid.hitsLeft();
  killCount++;
  asteroids.remove(asteroidId);
  
}




// Display the introduction screen.
void initScreen() {
  textSize(100);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("Asteroids", width/2, 150); 
  textSize(50);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("Click mouse to start the game.", width/2, 450); 
  textSize(25);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("W,A,S,D keys for movement, L/SPACEBAR to shoot, p to pause.", width/2, 750);
}

// Pause the game.
void pauseScreen() {
  noLoop();
}

// Gameplay.
void gameScreen() {
  background(0);// Set to black as per the original game.
  // Populate the ArrayList (backwards to avoid missing indexes) and project to the screen.
  for (int i = asteroids.size()-1; i >= 0; i--) { 
    Asteroid asteroid = asteroids.get(i);
    asteroid.move();
    asteroid.drawAsteroid(shapes[asteroid.shape]);
  }
  aScoreBoard.drawMe();
  detectCollisions();
  ship.updatePos();
  ship.edgeCheck();
  ship.display();
  updateAndDrawProjectiles();
}

void levelScreen() {
  background(0);
  textSize(100);
  fill(255, 255, 255);
  textAlign(CENTER);
  text(("Level - " + level), width/2, height/2);
}

// Displays the game over screen.
void gameOverScreen() {
  background(0);
  textSize(100);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("Game Over", width/2, 150); 
  textSize(25);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("Click mouse to start over.", width/2, 450);
  textSize(30);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("Your score was: " + aScoreBoard.score, width/2, 650);
  level = 1;
  numberAsteroids = level;
}

void gamePauseScreen() {
  background(0);
  textSize(100);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("Game Paused", width/2, 150); 
  textSize(25);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("Hit P to resume.", width/2, 450);

}

void nextLevel() {

  level++;
  asteroidSpeed+= 0.5;
  numberAsteroids = level;
  for (int i = 0; i < numberAsteroids; i++) { 
    createAsteroid(asteroidLife);
  }
}


void startGame() {
  gameScreen = 1;
}

void levelUp() {
  resetArrayLists();
  gameScreen = 2;
}

void gameOver() {
  resetArrayLists();
  gameScreen = 3;
}

void restart() {
  resetArrayLists();
  gameScreen = 0;
}
//Modified and placed inside detection loop.
void killCount() {
  killCount++;
  if (killCount == numberAsteroids*7) {
    nextLevel();
    killCount = 0;
    levelUp();
  }
}

void resetArrayLists(){
  projectiles.clear();
  asteroids.clear();
  
}

void mousePressed() {
  // if we are on the initial screen when clicked, start the game 
  if (gameScreen == 0) { 
    gameScreen = 2;
  } else if (gameScreen == 2) {
    gameScreen = 1;
  } else if (gameScreen == 3) { 
    setup();
    aScoreBoard.reset();
    gameScreen = 2;
  }
}

void keyPressed() {

  if (key == 'p' && gameScreen == 1) {
    gameScreen = 4;
  } else if (key == 'p' && gameScreen == 4) {
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
  if (key=='l'||key==' ' && gameScreen != 2) {//added spacebar for shooting
    sSHOOT=true;
  }
}
