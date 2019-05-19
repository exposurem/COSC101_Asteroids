/*
* File: Assignmment_3.pde
 * Group: Group 29
 * Date: 06/05/2019
 * Course: COSC101 - Software Development Studio 1
 * Desc: Asteroids game
 * Usage: Make sure to run in the processing environment, have the Minim sound library installed and press play etc...
 *
 Resource Credits
 Asteroid explosion - https://freesound.org/people/runningmind/sounds/387857/ 
 Shooting sound - https://freesound.org/people/alphatrooper18/sounds/362420/
 
 */

//import processing.sound.*;
import ddf.minim.*;
PShape randomShape;
//control key direction
boolean sUP, sDOWN, sRIGHT, sLEFT, sSHOOT;
// For the pause screen.
boolean paused;
// Maximum number of largest asteroids on screen
int numberAsteroids = 1;
// Game level.
int level = 1;
// Number of asteroids destroyed.
int killCount = 0;
// Asteroid hitpoints.
int asteroidLife = 3;
//Points awarded for hitting different size asteroids, three largest.
int asteroidOnePoints = 300;
int asteroidTwoPoints = 180;
int asteroidThreePoints = 100;
// Length of the shapes array
int shapeLength = 10;
// 0 = Start screen, 1 = gameplay, 2 = level, 3 = game over.
int gameScreen = 0;
// Number of ships remaining.
int playerLives = 3;
// Speed setting for asteroids.
float asteroidSpeed = 1; 
// Distance bullets travel before being removed.
float bulletMaxDistance;
float shipFriction; //resistance
float shipThrustFact;// initial thrust
float shipMaxSpd; //top speed
float shipSize; //ship radius
float shipTurnArc =6;
float shipMass = 1;
ArrayList<Asteroid> asteroids;
//ArrayList to store the projectile objects.
ArrayList<Projectile> projectiles;
// Array of randomly generated shapes.
PShape[] shapes = new PShape[shapeLength];
//ship object
Ship ship;
ScoreBoard aScoreBoard;
//SoundFile explosionSound;
//SoundFile shootSound;
Minim soundOne;
Minim soundTwo;
AudioSample shootSound;
AudioSample explosionSound;
AudioInput inputOne;
AudioInput inputTwo;



//Setting up outside of the setup() due to call from gameover. May need to split up things that
//need to be reset between games in another function, and leave setup for the things that are done once.



void setup() {
  
  frameRate(60);
  size(800, 800);
  shipStartSettings();
  ship = new Ship(shipFriction, shipThrustFact, shipMaxSpd, shipSize, shipMass, shipTurnArc);
  aScoreBoard = new ScoreBoard(400, 20);
  //explosionSound = new SoundFile(this, "explosion.wav");
  //shootSound = new SoundFile(this, "shooting.wav");
  soundOne = new Minim(this);
  soundTwo = new Minim(this);
  shootSound = soundOne.loadSample("shooting.wav");
  explosionSound = soundTwo.loadSample("explosion.wav");
  inputOne = soundOne.getLineIn();
  inputTwo = soundTwo.getLineIn();

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
  bulletMaxDistance = height*0.8;//move to settings class when made
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
  } else if (gameScreen == 4) {
    gamePauseScreen();
  } else if (gameScreen == 5) {
    deathScreen();
  }
}

/*
 Function: updateAndDrawProjectiles
 Purpose: To remove projectiles if they have travelled their max distance, or move and display the projectiles.
 Inputs: None.
 Outputs: None.
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
 Function: createAsteroid
 Purpose: Creates a new asteroid object and adds it to the asteroid arraylist.
 Inputs: An integer representing the life (number of hits) of the asteroid.
 Outputs: None.
 */
void createAsteroid(int asteroidLife) {
  
  PVector location = new PVector(random(random(0, 100)), random(width-100, width), random(height));
  PVector velocity = new PVector(random(-2, 2), random(-2, 2));
  int shape = chooseShape(shapeLength);
  asteroids.add(new Asteroid(location, velocity, asteroidLife, shape));
}

/*
 Function: splitAsteroid
 Purpose: When an asteroid with 3 or 2 hits reamining is destroyed, this function splits the asteroid into two smaller ones 
          with hits-1 remaining.
 Inputs: The asteroid object which was hit by a projectile with more than 1 life remaining.
 Outputs: None.
 */
void splitAsteroid(Asteroid asteroid ) {
  
  asteroids.add(new Asteroid(new PVector(asteroid.xPos(), asteroid.yPos()), (new PVector(random(-asteroidSpeed, asteroidSpeed), 
  random(-asteroidSpeed, asteroidSpeed))), asteroid.hits(), chooseShape(shapeLength)));
  asteroids.add(new Asteroid(new PVector(asteroid.xPos(), asteroid.yPos()), (new PVector(random(-asteroidSpeed, asteroidSpeed),
  random(-asteroidSpeed, asteroidSpeed))), asteroid.hits(), chooseShape(shapeLength)));
}

/*
Function: circleCollision
 Purpose: To detect collisions between asteroids & bullets, and asteroids and the player ship using circular based collision detection.
 Inputs: Floats representing the x & y coordinates of two objects (x,yPos1 & x,yPos2) and the detection radius of each object(radOne, radTwo).
 Outputs: Boolean true if a collision is detected, false if none was.
 */
boolean circleCollision(float xPos1, float yPos1, float radOne, float xPos2, float yPos2, float radTwo) {
  //Is the centre of each object closer than their combined radii.
  if (dist(xPos1, yPos1, xPos2, yPos2) < radOne + radTwo) {
    return true;
  }
  return false;
}

/*
Function: mapEdgeWrap
 Purpose: To detect if an object's PVector is leaving the screen bounds, and if so place them on the opposite side.
 Inputs: A PVector representing the object's location, and a float of the objects radius.
 Outputs: The original PVector if it is not leaving the screen, a modified PVector if it was leaving the screen.
 */
PVector mapEdgeWrap(PVector object, float radius) {
  //Checking left,right,top,bottom boundaries in order.
  if (object.x < -radius) {
    object.x = width+radius;
  } else if (object.x > width+radius) {
    object.x = -radius;
  }
  if (object.y <= -radius) {
    object.y = height+radius;
  } else if (object.y > height+radius) {
    object.y = -radius;
  }
  return object;
}

/*
Function: chooseShape
 Purpose: A utility function to provide a random number between 0 the int shapeLength which defines how many randomly
          shaped asteroid types there are to draw.
 Inputs: An integer configuration setting.
 Outputs: An integer between 0 and shapeLength
 */
int chooseShape(int shapeLength) {
  
  int number = int(random(0, shapeLength));
  return number;
}


void shipStartSettings() {
  shipFriction = 0.995;
  shipThrustFact = 0.15;
  shipMaxSpd = 10; 
  shipSize = 15;
  shipTurnArc =4;
}

//feel free to modify this class structure or give advice.
class Ship {

  PVector location, direction, noseLocation, acceleration, velocity;
  float xPos, yPos, noseX, noseY, radius; 
  float turnFactor, heading; 
  float resistance, mass, thrustFactor, maxSpeed;

  //Ship(float resistance, float maxSpeed, float radius, float accelerationSpeed,)//where size is radius
  Ship(float friction, float thrusting, float maxSpd, float radius, float mass, float turningArc) {
    //controls speed, amount of rotation and scale of ship, feel free to change
    //down to thrustFact can all be modified in our settings class once that's made
    this.resistance=friction;//lower = more resistance
    this.mass = mass;
    this.turnFactor = turningArc;//turning tightness
    this.maxSpeed = maxSpd;
    this.radius =radius;//size of ship and collision detection radius
    this.thrustFactor=thrusting;//propelling

    xPos = width/2.0; 
    yPos = height/2.0;
    //initialise vectors
    acceleration = new PVector(0, 0);
    velocity = new PVector(0, 0);
    location = new PVector(xPos, yPos+radius);
    noseLocation = new PVector(location.x, location.y-radius);
    heading = -HALF_PI;
    direction = PVector.fromAngle(heading);
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
      heading-=radians(turnFactor);
      direction=getDirection(direction, heading);
    }
    if (sRIGHT) {
      heading+=radians(turnFactor);
      direction=getDirection(direction, heading);
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
    PVector thrust = direction.copy();
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
  PVector getDirection(PVector vector, float heading) {
    vector.x = location.mag() * cos(heading);
    vector.y = location.mag() * sin(heading);
    return vector;
  }

  //Adds a new projectile
  void shoot() {
    
    shootSound.trigger();
    projectiles.add(new Projectile(direction, noseLocation, 6, bulletMaxDistance, velocity.mag()));
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

/*
 Class: Projectile
 Purpose: A class for the projectile objects.
 Inputs: PVectors representing the ship's current location and direction, an integer for the projectile speed,
         and floats for the projectile's maximum distance it can travel and its magnatude.
 Methods: move and display.
 */
class Projectile {
  
  PVector blocation = new PVector(), direction = new PVector(), velocity;
  float  distanceTravelled, maxDistance;
  int speed;
  boolean visible;
  float radius;
  float magnitude;

  Projectile(PVector shipDirection, PVector shipLocation, int speed, float maxDistance, float mag) {
    this.speed = speed;
    this.visible = true;
    this.blocation = blocation.set(shipLocation.x, shipLocation.y);
    this.direction =shipDirection.copy();
    this.direction.setMag(speed);
    this.radius = 5;
    this.maxDistance = maxDistance;
    this.distanceTravelled = 0;
    this.velocity = new PVector();
    this.magnitude = mag;
  }
  
 /*
  Method Purpose: To move the projectile on the screen, also adds the ship's velocity when fired.
  Inputs: None.
  Outputs: None.
  */
  void move() {
    //Adds the ship's current velocity to the projectiles.
    velocity.setMag(magnitude);  
    //Adds the bullets own velocity to it.
    velocity.add(direction);
    blocation.add(velocity);
    distanceTravelled +=velocity.mag();
  }
  
 /*
  Method Purpose: To draw the projectile.
  Inputs: None.
  Outputs: None.
  */
  void display() {

    ellipse(blocation.x, blocation.y, 5, 5);
  }
}

/*
 Class: ScoreBoard
 Purpose: A class to keep track of and display the score.
 Inputs: Floats representing the x and y coordinates of the centre of the score.
 Methods: update, reset, drawMe.
 */
class ScoreBoard {
  
  int score;
  float xPos;
  float yPos;

  ScoreBoard(float xPos, float yPos) {
    
    this.score = 0; 
    this.xPos = xPos;
    this.yPos = yPos;
  }
  
 /*
  Method Purpose: Updates the score.
  Inputs: An integer representing the amount of hits left the asteroid destoryed had.
  Outputs: None.
  */
  void update(int hitsLeft) {
    //Awards more points for hitting a smaller size asteroid.
    switch(hitsLeft) {
    case 1:
      score += asteroidOnePoints;
      break;
    case 2:
      score += asteroidTwoPoints;
      break;
    case 3: 
      score += asteroidThreePoints;
      break;
    }
  }

 /*
  Method Purpose: Resets the score.
  Inputs: None.
  Outputs: None.
  */
  void reset() {
    
    score = 0;
  }
  
 /*
  Method Purpose: Display the current score.
  Inputs: None.
  Outputs: None.
  */
  void drawMe() {
    textSize(20);
    fill(255, 255, 255);
    textAlign(CENTER);
    text("Score: " + aScoreBoard.score, aScoreBoard.xPos, aScoreBoard.yPos);
  }
}

/*
 Function: detectCollisions
 Purpose: A function check and handle collisions between the asteroids, projectiles and ship.
 Inputs: None.
 Outputs: None.
 */
void detectCollisions() {
  
  for (int i = asteroids.size()-1; i >= 0; i--) {
    Asteroid asteroid = asteroids.get(i);
    //Call the circle collision detection function between the players ship and the current asteroid object.
    if (circleCollision(ship.xPos, ship.yPos, ship.radius, asteroid.xPos(), asteroid.yPos(), asteroid.aRadius())) {
      lifeEnd();
      break;
    }
    //No collisions with the players ship found, compare the current asteroid to the projectiles.
    for (int j=projectiles.size()-1; j >= 0; j--) {
      Projectile bullet = projectiles.get(j);
      //Found a collision between the current asteroid and projectile.
      if (circleCollision(bullet.blocation.x, bullet.blocation.y, bullet.radius, asteroid.xPos(), asteroid.yPos(), asteroid.aRadius())){
        //Call functions and perform actions to handle the collision event
        handleAsteroidCollision(asteroid, i, j);
        //Check if all of the asteroids have been destroyed.
        if (killCount == numberAsteroids*7) {
          levelUp();
          nextLevel();
          killCount = 0;
        }
        //Split into new asteroids.
        if (asteroid.hits() >0) {
          splitAsteroid(asteroid);
        }
        break;
      }
    }
  }
}

/*
 Function: handleAsteroidCollision
 Purpose: A function to handle a collision between an asteroid and a projectile.
 Inputs: The asteroid object, and two integers representing the position of the projectile and asteroid objects within their arraylists.
 Outputs: None.
 */
void handleAsteroidCollision(Asteroid asteroid, int asteroidId, int projectileId) {
  
  explosionSound.trigger();
  aScoreBoard.update(asteroid.hitsLeft);
  projectiles.remove(projectileId);
  //Remove the life remaining of the asteroid
  asteroid.hitsLeft();
  //Keep track of how many asteroids have been destroyed.
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
  livesDisplay();
  detectCollisions();
  ship.updatePos();
  ship.edgeCheck();
  ship.display();
  updateAndDrawProjectiles();
}

void levelScreen() {
  background(0);
  livesDisplay();
  aScoreBoard.drawMe();
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

void deathScreen() {
  background(0);
  textSize(40);
  fill(255, 255, 255);
  textAlign(CENTER);
  if (playerLives == 1) {
    text("Ouch, you died. " +"\n" + playerLives + " life remaining.", width/2, height/2);
  } else {
    text("Ouch, you died. " +"\n" + playerLives + " lives remaining.", width/2, height/2);
  }
  resetArrayLists();
  killCount = 0;
  ship = new Ship(shipFriction, shipThrustFact, shipMaxSpd, shipSize, shipMass, shipTurnArc);
  numberAsteroids = level;
  for (int i = 0; i < numberAsteroids; i++) { 
    createAsteroid(asteroidLife);
  }
}

void nextLevel() {
  //experiment with these figures
  shipFriction -=0.001; //lower = more
  shipMaxSpd -= 0.25;
  shipThrustFact -=0.01;
  shipSize +=2;
  shipTurnArc+=0.5;//faster turning compensate slower speed
  ship = new Ship(shipFriction, shipThrustFact, shipMaxSpd, shipSize, shipMass, shipTurnArc);
  resetArrayLists();
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
  gameScreen = 2;
}

void gameOver() {
  gameScreen = 3;
}

void restart() {
  resetArrayLists();
  gameScreen = 0;
}

void death() {
  gameScreen = 5;
}

void resetArrayLists() {
  projectiles.clear();
  asteroids.clear();
}

void resetConditions() {
  resetArrayLists();
  shipStartSettings();
  ship = new Ship(shipFriction, shipThrustFact, shipMaxSpd, shipSize, shipMass, shipTurnArc);
  // Initialize the ArrayList.
  asteroids = new ArrayList<Asteroid>();
  for (int i = 0; i < numberAsteroids; i++) { 
    createAsteroid(asteroidLife);
  }
  killCount = 0;
  asteroidSpeed = 1;
  playerLives = 3;
  projectiles = new ArrayList<Projectile>();
  background(0);
}

void livesDisplay() {
  noFill();
  stroke(255);
  randomShape = createShape();
  randomShape.beginShape();
  randomShape.vertex(0, -25);//top
  randomShape.vertex(-25, 25);//bottom left
  randomShape.vertex(0, 25/2.0);//bottom middle
  randomShape.vertex(25, 25);//bottom right
  randomShape.endShape(CLOSE);
  if (playerLives == 3) {
    shape(randomShape, 50, 50);
    shape(randomShape, 100, 50);
    shape(randomShape, 150, 50);
  } else if (playerLives == 2) {
    shape(randomShape, 50, 50);
    shape(randomShape, 100, 50);
  } else if (playerLives == 1) {
    shape(randomShape, 50, 50);
  }
}

void lifeEnd() {
  if (playerLives > 0) {
    playerLives--;
    death();
  } else {
    gameOver();
  }
}

void mousePressed() {
  // if we are on the initial screen when clicked, start the game 
  if (gameScreen == 0) { 
    gameScreen = 2;
  } else if (gameScreen == 2) {
    gameScreen = 1;
  } else if (gameScreen == 3) { 
    resetConditions();
    aScoreBoard.reset();
    gameScreen = 2;
  } else if (gameScreen == 5) {
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
