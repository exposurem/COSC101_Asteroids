/*
 * File: Asteroids.pde
 * Group: Group 29
 * Date: 06/05/2019
 * Course: COSC101 - Software Development Studio 1
 * Desc: A remake of the classic Asteroids arcade game.
 * Installation: 
 *   Ensure the latest version of processing is installed (at least 3.5.3).
 *   Get it from https://processing.org/download/. After extracting the 
 *   contents of this archive ensure the following files were included:
 *       \Asteroids.pde
 *       \Data\explosion.wav
 *       \Data\shipexplosion.wav
 *       \Data\shooting.wav.
 *   The files may need to be manually added via the sketch/add file tab,
 *   depending on your system.
 *   Install the Minim sound library through processing.
 *
 *  
 * Resource Credits:
 * explosion.wav - https://freesound.org/people/runningmind/sounds/387857/ 
 * shooting.wav - https://freesound.org/people/alphatrooper18/sounds/362420/
 * shipexplosion.wav - https://freesound.org/people/cabled_mess/sounds/350972/
 *
 * References:
 * Ships PVectors/motion adapted/built upon from Daniel Shiffman's PVector
 * tutorial: https://processing.org/tutorials/pvector/
 *
 * Highscore JSON feature based on UNE's COSC101 lecture 12 on File I/O
 *
 * https://discourse.processing.org/ for help with screen states.
 *
 * Circle collision detection adapted from: https://happycoding.io/tutorials/
 * processing/collision-detection#circle-circle-collision/.
 */
 
 
// Minim sound library. 
import ddf.minim.*;
// Control key direction.
boolean sUP, sDOWN, sRIGHT, sLEFT, sSHOOT;
// For keypressed of player name entry.
boolean kbNameEntry;
// Maximum number of largest asteroids on screen.
int numberAsteroids = 1;
// Game level.
int level = 1;
// Number of asteroids destroyed.
int killCount = 0;
// Asteroid hitpoints.
int asteroidLife = 3;
// Points awarded for hitting different size asteroids, three largest.
int asteroidOnePoints = 300;
int asteroidTwoPoints = 180;
int asteroidThreePoints = 100;
// Length of the shapes array.
int shapeLength = 10;
// 0 = Start screen, 1 = gameplay, 2 = level, 3 = game over.
int gameScreen = 0;
// Number of ships remaining.
int playerLives = 3;
// Number of alien ships.
int aliens = 1;
// Ranmdom timer for appearance of alien ship.
float timer = random(10000);
// Speed setting for asteroids.
float asteroidSpeed = 1; 
// Distance bullets travel before being removed.
float bulletMaxDistance;
// Resistance.
float shipFriction;
// Initial thrust.
float shipThrustFact;
// Top speed.
float shipMaxSpd;
// Ship radius.
float shipSize;
// Ship's turning increment (theta)
float shipTurnArc =6;
float shipMass = 1;
// Volume control for sound effects.
float asteroidVolume = 1.5;
float shootVolume = 1;
float shipExplosionVolume = 1;
// Store the currently generated random shape.
PShape randomShape;
// Array of randomly generated shapes.
PShape[] shapes = new PShape[shapeLength];
// ArrayList to store the asteroid objects.
ArrayList<Asteroid> asteroids;
// ArrayList to store the projectile objects.
ArrayList<Projectile> projectiles;
// Local array's to store JSON data in program instance.
String[] playerName = new String[5];
int[] highscores = new int[5];//
JSONArray values;
// Entry to be added to playerName.
String entry = "";

// Alien ship as repurposed Asteroid object.
Asteroid alienShip;
// Ship object
Ship ship;
// Scoreboard object.
ScoreBoard aScoreBoard;
// Sound effect variables
Minim soundOne;
Minim soundTwo;
Minim soundThree;
AudioSample shootSound;
AudioSample explosionSound;
AudioSample shipExplosion;


void setup() {

  frameRate(60);
  size(800, 800);
  //Load high scores
  readInScores();
  shipStartSettings();
  alienShip = new Asteroid(new PVector(0, height/2), new PVector(1, 3));
  ship = new Ship(shipFriction, shipThrustFact, shipMaxSpd, shipSize, shipMass,
      shipTurnArc);
  aScoreBoard = new ScoreBoard(400, 20);
  soundOne = new Minim(this);
  soundTwo = new Minim(this);
  soundThree = new Minim(this);
  shootSound = soundOne.loadSample("shooting.wav");
  explosionSound = soundTwo.loadSample("explosion.wav");
  shipExplosion = soundThree.loadSample("shipexplosion.wav");
  shootSound.setGain(shootVolume);
  explosionSound.setGain(asteroidVolume);
  shipExplosion.setGain(shipExplosionVolume);
  smooth(); 
  // Generate an array of random asteroid shapes.
  drawShapes();
  for (int i = 0; i < shapes.length; i++) {
    shape(shapes[i], random(width), random(height), 100, 100);
  }
  // Initialize the ArrayList.
  asteroids = new ArrayList < Asteroid>();
  for (int i = 0; i < numberAsteroids; i++) { 
    createAsteroid(asteroidLife);
  }
  projectiles = new ArrayList < Projectile>();
  bulletMaxDistance = height * 0.8;
  background(0);
}

/*
 Class: Ship
 Purpose  : Generate's a ship object, along with value's defining variable's for
            each instance. Update's ship movement & rotation.
 Inputs   : None.
 Functions: updatePos, display, drawShip, drawExhaust, propel, edgeCheck, shoot,
            getDirection.
 */
class Ship {

  PVector location, direction, noseLocation, acceleration, velocity;
  float xPos, yPos, noseX, noseY, radius; 
  float turnFactor, heading; 
  float resistance, mass, thrustFactor, maxSpeed;

  Ship(float friction, float thrusting, float maxSpd, float radius, float mass,
      float turningArc) {

    // Ship resistance; lower = more.
    this.resistance = friction;
    // Ship mass.
    this.mass = mass;
    // Turning tightness.
    this.turnFactor = turningArc;
    // Maximum ship speed.
    this.maxSpeed = maxSpd;
    // Size of ship and collision detection radius.
    this.radius = radius;
    // Propelling force.
    this.thrustFactor = thrusting;

    xPos = width/2.0; 
    yPos = height/2.0;
    // Initialise PVectors.
    acceleration = new PVector(0, 0);
    velocity = new PVector(0, 0);
    location = new PVector(xPos, yPos + radius);
    noseLocation = new PVector(location.x, location.y - radius);
    heading = - HALF_PI;
    direction = PVector.fromAngle(heading);
  }

  /*
   Function: updatePos
   Purpose : Update's location, heading and velocity of PVector's, call's
             keypress functions.
   Inputs  : None.
   Outputs : None.
   */
  void updatePos() {
    
    xPos = location.x;
    yPos = location.y;
    heading = direction.heading();

    velocity.add(acceleration);
    velocity.mult(resistance);
    velocity.limit(maxSpeed);
    location.add(velocity);
    // Limit by resetting each frame.
    acceleration.set(0, 0);
    noseLocation.set(noseX, noseY);
    if (sUP) {
      propel();
    } 
    if (sDOWN) {
      propel();
    }
    if (sLEFT) {
      heading -= radians(turnFactor);
      direction = getDirection(direction, heading);
    }
    if (sRIGHT) {
      heading += radians(turnFactor);
      direction = getDirection(direction, heading);
    }
    if (sSHOOT) {
      shoot();
      sSHOOT = false;
    }
  }

  /*
   Function: display
   Purpose : Using a matrix at current x & y coord's, rotates and displays
             via drawShip().
   Inputs  : None.
   Outputs : None.
   */
  void display() {

    pushMatrix();
    translate(location.x, location.y);
    rotate(heading + HALF_PI);
    noFill();
    drawShip();
    if (sUP) {
      drawExhaust();
    }
    //Coordinates for nose outside of matrix.
    noseX = screenX(0, -radius);
    noseY = screenY(0, -radius);
    popMatrix();
    stroke(255);
  }

  /*
   Function: drawShip
   Purpose : Draw's vertex ship at current location, based on triangle.
   Inputs  : None.
   Outputs : None.
   */
  void drawShip() {

    stroke(255);
    beginShape();
    vertex(0, -radius);//top
    vertex(-radius, radius);//bottom left
    vertex(0, radius/2.0);//bottom middle
    vertex(radius, radius);//bottom right
    endShape(CLOSE);
  }

  /*
   Function: drawExhaust
   Purpose : Draw's flame for ship while propelling forwards.
   Inputs  : None
   Outputs : None.
   */
  void drawExhaust() {

    stroke(255);
    beginShape();
    vertex(0, radius/2.0);
    vertex(-radius/2.0, radius * 0.75);
    vertex(0, radius * 1.5);
    vertex(radius/2.0, radius * 0.75);
    endShape(CLOSE);
  }

  /*
   Function: propel
   Purpose : Propels ship in direction of heading, capable of reversing too.
   Inputs  : None.
   Outputs : None.
   */
  void propel() {

    PVector thrust = direction.copy();
    if (sUP) {
      //forwards
      thrust.setMag(thrustFactor);
    }
    if (sDOWN) {
      //reverse
      thrust.setMag(-thrustFactor);
    }
    acceleration.div(mass);
    acceleration.add(thrust);
  }

  /*
   Function: edgeCheck
   Purpose : Calls mapEdgeWrap(), wrapping ship location if exceeding map bounds.
   Inputs  : None
   Outputs : None
   */
  void edgeCheck() {

    PVector checkedLocation = mapEdgeWrap(location, radius);
    location = checkedLocation;
  }

  /*
   Function: getDirection
   Purpose : Returns a PVector with it's x & y coordinates adjusted for direction.
   Inputs  : PVector and directional heading.
   Outputs : PVector with updated direction.
   */
  PVector getDirection(PVector vector, float heading) {

    vector.x = location.mag() * cos(heading);
    vector.y = location.mag() * sin(heading);
    return vector;
  }
 
  /*
   Function: momentumToHeading()
   Purpose : Checks if ship momentum is moving to relative to ship heading.
   Inputs  : None
   Outputs : True or False boolean
   */  
  boolean momentumToHeading(){
    
    float velFacingDiff = (abs(velocity.heading()-heading));
    // Checks if velocity is within relative (+90,-90) degrees from heading.
    if (velFacingDiff < HALF_PI && velFacingDiff > (-HALF_PI)){
      return true;
    }else{
      return false;
    }
  }
   
  /*
   Function: shoot
   Purpose : Call shootSound.trigger() for sound, creates a projectile object.
   Inputs  : None.
   Outputs : None.
   */
  void shoot() {
    
    float bulletMag;
    // If ship's facing and momentum coincide, add ship's velocity to bullet.
    if(momentumToHeading()){
      bulletMag = velocity.mag(); 
    }
    // if moving (relative) backwards set to 0.
    else{
      bulletMag=0;  
    }  
    
    shootSound.trigger();
    projectiles.add(new Projectile(direction, noseLocation, 6, 
        bulletMaxDistance, bulletMag));
  }
}

  /*
   Class    : Asteroid
   Purpose  : To generate an asteroid object.
   Inputs   : PVectors for the location and direction of the asteroid. Ints
              for random shape generation and determination of asteroid size.
   Functions: drawAsteroid, move, xPos, yPos, hitsLeft, aRadius, hits.
   */
class Asteroid {
  
  // Location of the asteroid.
  PVector location;
  // Speed of the asteroid.
  PVector velocity;
  // Number of times to hit before destroyed completely.
  int hitsLeft;
  // Base radius of the asteroid.
  float radius = 50;
  // Random number to pick from shape array for asteroid.
  int shape;
  // Boolean for visual status of alien ship.
  boolean show = true;
  // Store the alien ship design.
  PShape alienShip;
  
  // Initialise.
  Asteroid(PVector location, PVector velocity, int hitsLeft, int shape) {
    this.location = location;
    this.velocity = velocity;
    this.hitsLeft = hitsLeft;
    this.shape = shape;
  }
  // Constructor for the alien ship.
  Asteroid(PVector location, PVector velocity) {
    this.location = location;
    this.velocity = velocity;
  }

  /*
   Function: drawAsteroid
   Purpose : Draw each Asteroid to the screen at the appropriate size.
   Inputs  : PShape of randomly generated asteroid.
   Outputs : None.
   */
  void drawAsteroid(PShape shapes) {

    if (hitsLeft == 3) {
      shape(shapes, location.x, location.y, radius*3, radius*3);
    } else if (hitsLeft == 2) {
      shape(shapes, location.x, location.y, radius*2, radius*2);
    } else if (hitsLeft == 1) {
      shape(shapes, location.x, location.y, radius, radius);
    }
  }
  
  /*
   Function: drawAlien
   Purpose : Draw the alien ship to the screen.
   Inputs  : None.
   Outputs : None.
   */
  void drawAlien() {

    if (show == true) {
      noFill();
      stroke(255);
      beginShape();
      alienShip = createShape();
      alienShip.beginShape();
      alienShip.vertex(-10, 10);//bottom right
      alienShip.vertex(0, 0); //centre
      alienShip.vertex(20, 0);//bottom left
      alienShip.vertex(30, 10);//bottom middle
      alienShip.vertex(20, 20);//bottom right
      alienShip.vertex(0, 20);//bottom right
      alienShip.vertex(-10, 10);//bottom right
      alienShip.vertex(30, 10);//bottom middle
      shape(alienShip, location.x, location.y);
    }
  }
  
  /*
   Function: showAlien
   Purpose : Switch shown state of alien switch to false.
   Inputs  : None.
   Outputs : None.
   */
  void showAlien() {

    show = false;
  }
  
  /*
   Function: randomAlien
   Purpose : Controls movement of alien ship.
   Inputs  : None.
   Outputs : None.
   */
  void randomAlien() {

    location.add(velocity);
    if (location.y > 550) {
      velocity.y = -3;
    } 
    if (location.y < 275) {
      velocity.y = 3;
    }
  }

  /*
   Function: move
   Purpose : Handles asteroid movement and boundary checking.
   Inputs  : None.
   Outputs : None.
   */
  void move() {

    location.add(velocity);
    // Boundary checking
    PVector checkedLocation = mapEdgeWrap(location, radius);
    location = checkedLocation;
  }

  /*
   Function: hitsLeft
   Purpose: Subtracts a point from the asteroids life.
   Inputs: None.
   Outputs: None.
   */
  void hitsLeft() {

    hitsLeft--;
  }

  /*
   Function: aRadius
   Purpose : Sets radius of the asteroid according to the number of hitsLeft.
   Inputs  : None.
   Outputs : Returns the appropriate radius.
   */
  float aRadius() {

    if (hitsLeft == 3) {
      return (radius*3)/2;
    } else if (hitsLeft == 2) {
      return (radius*2)/2;
    } else return radius/2;
  }

  /*
   Function: hits
   Purpose : Returns current number of hits asteroid can sustain.
   Inputs  : None.
   Outputs : Returns the number of hits left.
   */
  int hits() {

    return hitsLeft;
  }
}

/*
 Class: Projectile
 Purpose: A class for the projectile objects.
 Inputs : PVectors representing the ship's current location and direction, an
          integer for the projectile speed, and floats for the projectile's
          maximum distance it can travel and its magnitude.
 Methods: move and display.
 */
class Projectile {
  
  // Location & Velocity PVectors.
  PVector blocation = new PVector(), direction = new PVector(), velocity;
  // Max distance and distance travelled.
  float  distanceTravelled, maxDistance;
  int speed;
  float radius;
  float magnitude;

  Projectile(PVector shipDirection, PVector shipLocation, int speed,
      float maxDistance, float magnitude) {
    this.speed = speed;
    this.blocation = blocation.set(shipLocation.x, shipLocation.y);
    this.direction = shipDirection.copy();
    this.direction.setMag(speed);
    this.radius = 5;
    this.maxDistance = maxDistance;
    this.distanceTravelled = 0;
    this.velocity = new PVector();
    this.magnitude = magnitude;
  }

  /*
   Function: move
   Purpose : To move the projectile on the screen, also adds the ship's
             velocity when fired.
   Inputs  : None.
   Outputs : None.
   */
  void move() {
    
    //Adds the ship's current velocity to the projectiles.
    velocity.setMag(magnitude);  
    //Adds the bullets own velocity to it.
    velocity.add(direction);
    blocation.add(velocity);
    distanceTravelled += velocity.mag();
  }

  /*
   Function: display
   Purpose : To draw the projectile.
   Inputs  : None.
   Outputs : None.
   */
  void display() {

    ellipse(blocation.x, blocation.y, 5, 5);
  }
}

/*
 Class  : ScoreBoard
 Purpose: A class to keep track of and display the score.
 Inputs : Floats representing the x and y coordinates of the centre of the score.
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
   Function: update
   Purpose : Updates the score.
   Inputs  : Integer representing the amount of hits left the asteroid destroyed had.
   Outputs : None.
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
   Function: reset
   Purpose : Resets the score.
   Inputs  : None.
   Outputs : None.
   */
  void reset() {

    score = 0;
  }

  /*
   Function: drawMe
   Purpose : Display the current score.
   Inputs  : None.
   Outputs : None.
   */
  void drawMe() {
    
    textSize(20);
    fill(255, 255, 255);
    textAlign(CENTER);
    text("Score: " + aScoreBoard.score, aScoreBoard.xPos, aScoreBoard.yPos);
  }
}

void draw() {
  
  // Controls gameplay flow via screen selection.
  if (gameScreen == 0) {
    startScreen();
  } else if (gameScreen == 1) {
    gamePlayScreen();
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
 Function: startScreen
 Purpose: Display the introduction screen.
 Inputs: None.
 Outputs: None.
 */
void startScreen() {
  
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

/*
 Function: gamePlayScreen
 Purpose : Display the main game screen and run the major game related functions.
 Inputs  : None.
 Outputs : None.
 */
void gamePlayScreen() {
  
  // Set to black as per the original game.
  background(0);
  // Populate the asteroids ArrayList (backwards to avoid missing indexes) and
  // project to the screen.
  for (int i = asteroids.size()-1; i >= 0; i--) { 
    Asteroid asteroid = asteroids.get(i);
    asteroid.move();
    asteroid.drawAsteroid(shapes[asteroid.shape]);
  }
  if (millis() > timer){
  alienShip.drawAlien();
  alienShip.move();
  alienShip.randomAlien();
  }
  aScoreBoard.drawMe();
  livesDisplay();
  detectCollisions();
  ship.updatePos();
  ship.edgeCheck();
  ship.display();
  updateAndDrawProjectiles();
}

/*
 Function: levelScreen
 Purpose : Display the level screen as well as the score and lives remaining.
 Inputs  : None.
 Outputs : None.
 */
void levelScreen() {
  
  background(0);
  livesDisplay();
  aScoreBoard.drawMe();
  textSize(100);
  fill(255, 255, 255);
  textAlign(CENTER);
  text(("Level - " + level), width/2, height/2);
  textSize(25);
  text("Click mouse to continue.", width/2, height*0.9);
}

/*
 Function: gameOverScreen
 Purpose : Display the game over screen, reset level and number of asteroids.
 Inputs  : None.
 Outputs : None.
 */
void gameOverScreen() {
  
  background(0);
  textSize(100);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("Game Over", width/2, 150);
  displayHighScores();
  textSize(25);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("Click mouse to start over.", width/2, 450);
  textSize(30);
  fill(255, 255, 255);
  textAlign(CENTER);
  text("Your score was: " + aScoreBoard.score, width/2, 650);
  level = 1;
  aliens = 1;
  timer = millis() + random(10000);
  numberAsteroids = level;
}

/*
 Function: gamePauseScreen
 Purpose : Display the pause screen.
 Inputs  : None.
 Outputs : None.
 */
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

/*
 Function: deathScreen
 Purpose : Display the ship destroyed screen, reset necessary variables and 
           generate a new ship and asteroids.
 Inputs  : None.
 Outputs : None.
 */
void deathScreen() {
  
  background(0);
  textSize(40);
  fill(255, 255, 255);
  textAlign(CENTER);
  if (playerLives == 1) {
    text("Ouch, you died. " +"\n" + playerLives + " spare ship remaining.",
        width/2, height/2);
  } else {
    text("Ouch, you died. " +"\n" + playerLives + " spare ships remaining.",
        width/2, height/2);
  }
  textSize(25);
  text("Click mouse to continue.", width/2, height*0.9);
  resetArrayLists();
  alienShip = new Asteroid(new PVector(0, 400), new PVector(1, 3));
  killCount = 0;
  aliens = 1;
  timer = millis() + random(10000);
  ship = new Ship(shipFriction, shipThrustFact, shipMaxSpd, shipSize, shipMass,
      shipTurnArc);
  numberAsteroids = level;
  for (int i = 0; i < numberAsteroids; i++) { 
    createAsteroid(asteroidLife);
  }
}

/*
 Function: livesDisplay
 Purpose : Draw and display images representing ships remaining.
 Inputs  : None.
 Outputs : None.
 */
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

/*
 Function: detectCollisions
 Purpose : A function to check and handle collisions between the asteroids, 
           projectiles and ships.
 Inputs  : None.
 Outputs : None.
 */
void detectCollisions() {
  
  // Check if the asteroids and alien ship have been destroyed.
  if (killCount == numberAsteroids*7 && aliens == 0) {
    levelUp();
    nextLevel();
    killCount = 0;
  }
  // Check if the alien ship exists check for a collision with the player ship.
  if (aliens == 1 && alienShip.show) {
    if (circleCollision(ship.xPos, ship.yPos, ship.radius, alienShip.location.x,
        alienShip.location.y, alienShip.aRadius())) {
      // Call function and perform actions to handle the collision event
      handleAlienCollison();
      return;
    }
    // If the alien ship is alive but there are no asteroids. This statement only
    // runs another loop through the projectile array if needed.
    if(asteroids.size() == 0){
      for (int j = projectiles.size()-1; j >= 0; j--){
        Projectile bullet = projectiles.get(j);
        if (circleCollision(bullet.blocation.x, bullet.blocation.y, bullet.radius,
            alienShip.location.x, alienShip.location.y, alienShip.aRadius())) {
          // Call function and perform actions to handle the collision event
          handleAlienCollision(j);
        }
      } 
    }
  }
  // Iterate through the asteroids arraylist to check for collisions.
  for (int i = asteroids.size()-1; i >= 0; i--) {
    Asteroid asteroid = asteroids.get(i);
    // Call the circle collision detection function between the players ship and
    // the current asteroid object.
    if (circleCollision(ship.xPos, ship.yPos, ship.radius, asteroid.location.x,
        asteroid.location.y, asteroid.aRadius())) {
      shipExplosion.trigger();
      lifeEnd();
      break;
    }
    // No collisions with the players ship or alien ship found, compare the projectiles
    // to the asteroids and alien ship if it is visible.
    for (int j = projectiles.size()-1; j >= 0; j--) {
      Projectile bullet = projectiles.get(j);
      // If the alien ship is displayed, check for a collision against a projectile.
      if (aliens == 1){
        if (circleCollision(bullet.blocation.x, bullet.blocation.y, bullet.radius,
            alienShip.location.x, alienShip.location.y, alienShip.aRadius())) {
          // Call function and perform actions to handle the collision event
          handleAlienCollision(j);
          break;
        }  
      }
      //Found a collision between the current asteroid and projectile.
      if (circleCollision(bullet.blocation.x, bullet.blocation.y, bullet.radius,
          asteroid.location.x, asteroid.location.y, asteroid.aRadius())) {
        // Call function and perform actions to handle the collision event
        handleAsteroidCollision(asteroid, i, j);
        //Split into new asteroids.
        if (asteroid.hits() > 0) {
          splitAsteroid(asteroid);
        }
        break;
      }
    }
  }
}

/*
 Function: handleAlienCollison (Overloaded)
 Purpose : Handles the collision events involving the alien ship.
 Inputs  : None / integer of the projectile position within the arrayList.
 Outputs : None.
 */
void handleAlienCollison() {
  
    shipExplosion.trigger();
    lifeEnd();
    alienShip.showAlien();
}

void handleAlienCollision(int projectileId){
  
  alienShip.showAlien();
  shipExplosion.trigger();
  aScoreBoard.score += asteroidOnePoints;
  aliens = 0;
  projectiles.remove(projectileId);
}

/*
 Function: circleCollision
 Purpose : To detect collisions between asteroids & bullets, and asteroids and the
           player ship using circular based collision detection.
 Inputs  : Floats representing the x & y coordinates of two objects (x,yPos1 & x,yPos2)
           and the detection radius of each object(radOne, radTwo).
 Outputs : Boolean true if a collision is detected, false if none was.
 */
boolean circleCollision(float xPos1, float yPos1, float radOne, float xPos2, float yPos2, float radTwo) {
  
  //Is the centre of each object closer than their combined radii.
  if (dist(xPos1, yPos1, xPos2, yPos2) < radOne + radTwo) {
    return true;
  }
  return false;
}

/*
 Function: handleAsteroidCollision
 Purpose : A function to handle a collision between an asteroid and a projectile.
 Inputs  : The asteroid object, and two integers representing the position of the 
           projectile and asteroid objects within their arraylists.
 Outputs : None.
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
 Purpose : When an asteroid with 3 or 2 hits reamining is destroyed, this function
           splits the asteroid into two smaller ones with hits-1 remaining.
 Inputs  : The asteroid object which was hit by a projectile with more than 1 life remaining.
 Outputs : None.
 */
void splitAsteroid(Asteroid asteroid ) {

  asteroids.add(new Asteroid(new PVector(asteroid.location.x, asteroid.location.y),
      (new PVector(random(-asteroidSpeed, asteroidSpeed), random(-asteroidSpeed, asteroidSpeed))),
       asteroid.hits(), chooseShape(shapeLength)));
       
  asteroids.add(new Asteroid(new PVector(asteroid.location.x, asteroid.location.y),
      (new PVector(random(-asteroidSpeed, asteroidSpeed), random(-asteroidSpeed, asteroidSpeed))),
      asteroid.hits(), chooseShape(shapeLength)));
}

/*
 Function: mapEdgeWrap
 Purpose : To detect if an object's PVector is leaving the screen bounds, and if so
           place them on the opposite side.
 Inputs  : A PVector representing the object's location, and a float of the objects radius.
 Outputs : The original PVector if it is not leaving the screen, a modified PVector
           if it was leaving the screen.
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
 Function: updateAndDrawProjectiles
 Purpose : To remove projectiles if they have travelled their max distance, or move
           and display the projectiles.
 Inputs  : None.
 Outputs : None.
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
 Function: displayHighScores
 Purpose : Display new and overall highscore's.
 Inputs  : None.
 Outputs : None.
 */
void displayHighScores() {
  
  textSize(20);
  fill(255);
  textAlign(LEFT);
  float columnOne = 0.25;
  float columnTwo = 0.375;
  float columnThree = 0.625;
  int verticalSpacing = 20;
  float textY = 750;
  if (kbNameEntry){
    textAlign(CENTER);
    String prompt = "New High Score! enter name:";
    float cursorX = width/2 + (textWidth(prompt+entry)/2.0);
    text(prompt+entry, width/2, textY);
    // Line to show cursor position.
    line(cursorX, textY-textAscent(), cursorX, textY+textDescent());
  }    
  else{    
    for (int i = 0; i < highscores.length; i++) {
      if (highscores[i] != 0) {
        if (playerName[i] == ""){
          playerName[i] = entry;
        }        
        text("Rank:"+(i+1), columnOne*width, (height/4)+(i*verticalSpacing));
        text("Name:"+playerName[i], columnTwo*width, (height/4)+(i*verticalSpacing));
        text("Score:"+highscores[i], columnThree*width, (height/4)+(i*verticalSpacing));
      }    
    }
  } 
}

/*
 Function: resetArrayLists
 Purpose : Resets the arraylists.
 Inputs  : None.
 Outputs : None.
 */
void resetArrayLists() {
  
  projectiles.clear();
  asteroids.clear();
}

/*
 Function: readInScores.
 Purpose : Gets the current high scores from json file, stores in array's.
 Inputs  : None.
 Outputs : None.
 */
void readInScores() {
  
  File temp = new File(dataPath("highscores.json")); 
  //Only loads if existing JSON file.
  if (temp.exists()) {
    values = loadJSONArray(temp);    
    for (int i = 0; i < values.size(); i++) {
      JSONObject entry = values.getJSONObject(i);
      highscores[i] = entry.getInt("Highscore");
      playerName[i] = entry.getString("Name");
    }
  }
}

/*
 Function: shipStartSettings()
 Purpose : Set's value of Ship object parameter's, called upon game start &
           restart following a game over.
 Inputs  : None.
 Outputs : None.
 */
void shipStartSettings() {
  
  shipFriction = 0.995;
  shipThrustFact = 0.15;
  shipMaxSpd = 10;
  shipSize = 15;
  shipTurnArc = 4;
}

/*
 Function: drawShapes
 Purpose : To fill an array with a series of randomly generates shapes that will
           be used for the asteroids.
 Inputs  : None.
 Outputs : None.
 */
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



/*
 Function: chooseShape
 Purpose : A utility function to provide a random number between 0 the int 
           shapeLength which defines how many randomly shaped asteroid types
           there are to draw.
 Inputs  : An integer configuration setting.
 Outputs : An integer between 0 and shapeLength
 */
int chooseShape(int shapeLength) {

  int number = int(random(0, shapeLength));
  return number;
}

/*
 Function: nextLevel
 Purpose : Adjust parameters need for the next level, including difficulty increases.
 Inputs  : None.
 Outputs : None.
 */
void nextLevel() {
  
  if (shipFriction > 0.985){
    shipFriction -= 0.001;
  }
  if(shipMaxSpd > 8){
    shipMaxSpd -= 0.2;
  }
  if(shipThrustFact > 0.10){
    shipThrustFact -= 0.005;
  }
  if (shipSize < 25){
    shipSize += 1.5;
  }
  if (shipTurnArc < 8){
    shipTurnArc += 0.2;
  }
  ship = new Ship(shipFriction, shipThrustFact, shipMaxSpd, shipSize, shipMass, shipTurnArc);
  alienShip = new Asteroid(new PVector(0, height/2), new PVector(1, 3));
  resetArrayLists();
  aliens = 1;
  timer = millis() + random(10000);
  level++;
  asteroidSpeed += 0.5;
  numberAsteroids = level;
  for (int i = 0; i < numberAsteroids; i++) { 
    createAsteroid(asteroidLife);
  }
}

/*
 Function: startGame
 Purpose : Sets gameScreen appropriately.
 Inputs  : None.
 Outputs : None.
 */
void startGame() {
  
  gameScreen = 1;
}

/*
 Function: levelUp
 Purpose : Sets gameScreen appropriately.
 Inputs  : None.
 Outputs : None.
 */
void levelUp() {
  
  gameScreen = 2;
}

/*
 Function: gameOver
 Purpose : Sets gameScreen appropriately.
 Inputs  : None.
 Outputs : None.
 */
void gameOver() {
  
  updateScores(aScoreBoard.score);
  saveScores();
  gameScreen = 3;
}

/*
 Function: restart
 Purpose : Sets gameScreen appropriately, resets arraylists.
 Inputs  : None.
 Outputs : None.
 */
void restart() {
  
  resetArrayLists();
  gameScreen = 0;
}

/*
 Function: death
 Purpose : Sets gameScreen appropriately.
 Inputs  : None.
 Outputs : None.
 */
void death() {
  
  gameScreen = 5;
}

/*
 Function: resetConditions
 Purpose : Resets all game parameters, preparing for a fresh new game.
 Inputs  : None.
 Outputs : None.
 */
void resetConditions() {
  
  resetArrayLists();
  shipStartSettings();
  entry = "";
  alienShip = new Asteroid(new PVector(0, height/2), new PVector(1, 3));
  ship = new Ship(shipFriction, shipThrustFact, shipMaxSpd, shipSize, shipMass, shipTurnArc);
  // Initialize the ArrayList.
  asteroids = new ArrayList<Asteroid>();
  for (int i = 0; i < numberAsteroids; i++) { 
    createAsteroid(asteroidLife);
  }
  killCount = 0;
  asteroidSpeed = 1;
  playerLives = 3;
  aliens = 1;
  projectiles = new ArrayList<Projectile>();
  background(0);
}

/*
 Function: lifeEnd
 Purpose : Check for game over condition after player death, updates number of player lives.
 Inputs  : None.
 Outputs : None.
 */
void lifeEnd() {
  
  if (playerLives > 0) {
    playerLives--;
    death();
  } else {
    gameOver();
  }
}

/*
 Function: updateScores
 Purpose : Updates local copy of player highscores.
 Inputs  : score.
 Outputs : None.
 */
void updateScores(int score) {
  
  // Sets new entry to empty string, to be filled out later.
  String name = ""; 
  for (int i = 0; i<highscores.length; i++) {
    if (highscores[i] < score) {
      kbNameEntry = true;
      // Updates score/name, shifts previous down a position.
      int tempScore = highscores[i];
      highscores[i] = score;
      score = tempScore;
      String tempName = playerName[i];
      playerName[i] = name;      
      name = tempName;
    }
  }
}

/*
 Function: nameEntry
 Purpose : For each keypress, appends to entry.
 Inputs  : None.
 Outputs : None.
 */
void nameEntry() { 
  
  // Called for each keypress event, appends key to entry
  if (key == ENTER || key == RETURN) {    
    kbNameEntry = false;
  } else if (key == BACKSPACE && entry.length() > 0) {     
        entry = entry.substring(0, entry.length()-1);
    // Ensure key entry is <=10, alphanumerical characters.
  } else if ((entry.length() < 10) && (key>31) && (key!=CODED)) {
      entry += key;
  }
}

/*
 Function: saveScores
 Purpose : Stores highscores in a JSON file.
 Inputs  : None.
 Outputs : None.
 */
void saveScores() {
  
  values = new JSONArray();  
  // Goes through updated array, saving to JSON file.
  for (int i = 0; i < highscores.length; i++) {
    JSONObject entry = new JSONObject();
    entry.setInt("Rank", i+1);
    entry.setInt("Highscore", highscores[i]);
    entry.setString("Name", playerName[i]);
    values.setJSONObject(i, entry);
  }
  saveJSONArray(values, "data/highscores.json");
}

/*
 Function: exit
 Purpose : Inbuilt function to be called upon program exit.
 Inputs  : None.
 Outputs : None.
 */
void exit() {
  
  saveScores();
}

void mousePressed() {
  
  // Until name entry finished, no mouse events.
  if(!kbNameEntry){
    // Decides which screen to dislay on mouse pressed based on current screen.
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
}

void keyPressed() {
  
  // Give's key precedent to name entry.
  if (kbNameEntry) {
    nameEntry();
  }  
  else{
    if (key == 'p' && gameScreen == 1) {
      gameScreen = 4;
    } else if (key == 'p' && gameScreen == 4) {
      gameScreen = 1;
    }
    
    if (key == 'w' || keyCode == UP) {
      sUP=true;
    }
    if (key == 's' || keyCode == DOWN) {
      sDOWN=true;
    }
    if (key == 'd' || keyCode == RIGHT) {
      sRIGHT=true;
    }
    if (key == 'a' || keyCode == LEFT) {
      sLEFT=true;
    }
  }
}

void keyReleased() {
  
  if (key == 'w' || keyCode == UP) {
    sUP=false;
  }
  if (key == 's' || keyCode == DOWN) {
    sDOWN=false;
  }
  if (key == 'd' || keyCode == RIGHT) {
    sRIGHT=false;
  }
  if (key == 'a' || keyCode == LEFT) {
    sLEFT=false;
  }
  if (gameScreen == 1 && (key == 'l' || key == ' ')) {
    sSHOOT = true;
  }
}
