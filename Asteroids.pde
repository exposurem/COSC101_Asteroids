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
PShape[] shapes = new PShape[10];
PShape spaceship;//consider changing to image
boolean sUP, sDOWN, sRIGHT, sLEFT, sSHOOT;//control key direction
Ship ship;//ship object
// Maximum number of largest asteroids on screen... Can tie to level.
int numberAsteroids = 5;
// Asteroid hitpoints.
int asteroidLife = 3;
//configuration setting
float bulletMaxDistance = 500;

void setup() {
  frameRate(60);
  size(800, 800);
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


//TO BE MODIFIED ONCE EDGE OF MAP DETECTION FUNCTION IS REFACTORED.
/*
Function Purpose: To remove projectiles from the array if they go beyond the bounds of the screen.
 Called from: **
 Inputs: floats representing the x & y coordinates of two objects (x,yPos1 & x,yPos2) and the detection radius of each object.
 */
void updateAndDrawProjectiles() {

  for (int i = projectiles.size()-1; i >= 0; i--) { 
    Projectile bullets = projectiles.get(i);  

    if (bullets.blocation.x >= width  || bullets.blocation.x <= 0 || bullets.blocation.y >= height || bullets.blocation.y <=0 || bullets.distanceTravelled >= bulletMaxDistance) {
      projectiles.remove(i);
    } else {
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
boolean circleCollision(float xPos1, float yPos1, float radOne, float xPos2, float yPos2, float radTwo) {

  if (dist(xPos1, yPos1, xPos2, yPos2) < radOne + radTwo) {
    //There is a collision
    return true;
  }
  return false;
}

//feel free to modify this class structure or give advice.
class Ship {

  PVector location, dir, noseLocation, acceleration, velocity;
  int bulletSpeed; //changed from moveSpeed
  float xPos, yPos, noseX,noseY,shipRad;
  float radius, x1, y1, x2, y2, x3, y3,yNoseOffset; //semi-redundant, will clean up once sorted
  float turnFactor;
  float topSpeed;
  float resistance, mass, thrustFactor;
  float heading;

  Ship() {

    //controls speed, amount of rotation and scale of ship, feel free to change
    bulletSpeed=10;//might be worth moving to bullet class, no longer used on ship.
    resistance=0.995;//lower = resistance
    mass = 1;
    turnFactor =6;//turning tightness
    topSpeed = 8;
    shipRad =30;//size of ship
    thrustFactor=0.15;//propelling

    
    x1 =0;y1=-shipRad;//top
    x2=-shipRad;y2=shipRad;//bottom left
    x3=shipRad;y3=shipRad;//bottom right
    //might have to update radius, ship no longer based on equilateral triangle.
    //radius=shipRad;//think this should work, untested though.
    //Collision detection radius.
    radius = (abs(x2) + abs(x3)) /2;
    yNoseOffset = -27;
    
    //random starting coordinates
    xPos=random(shipRad, width-shipRad);
    yPos=random(0, height-(shipRad*2));

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
    acceleration.mult(0);//reset acceleration
    noseLocation.set(noseX,noseY);//not sure if this needs to be a PVector but ship can now shoot from nose based on noseX&Y

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
      force.mult(thrustFactor);
    }
    if (sDOWN) {
      force.mult(-thrustFactor);
    }
    applyForce(force);
  }
  void display() {
pushMatrix();
    translate(location.x, location.y+shipRad);
    rotate(heading+HALF_PI);
    fill(175);
    stroke(175);
    beginShape();
    vertex(x1, y1);//top
    vertex(x2, y2);//bottom left
    vertex(0, shipRad/2.0);//bottom middle
    vertex(x3, y3);//bottom right
    endShape(CLOSE);
    //coordinates for nose outside of matrix
    noseX=screenX(0,y1);
    noseY=screenY(0,y1);
    popMatrix();
    fill(255);
    
    //ellipse(noseLocation.x,noseLocation.y,5,5);//ship nose location
    //ellipse(location.x, location.y+shipRad, 5, 5);//ship center of rotation
  }

  void edgeCheck() {
    if (location.x < -shipRad) { //left
      location.x = width+shipRad;
    } else if (location.x > width+shipRad) { //right
      location.x = -shipRad;
    }
    if (location.y <= -shipRad*2) { //top
      location.y = height;
    } else if (location.y > height) { //bottom
      location.y = -shipRad*2;
    }
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
    this.direction = direction.set(shipDirection.x, shipDirection.y);
    this.radius = 5;
    this.maxDistance = maxDistance;
    this.distanceTravelled = 0;
  }


  //Update position of projectile
  void move() {
    distanceTravelled += 1;
    println(distanceTravelled);
    blocation.add(direction);
  }

  void display() {
    //Draw bullet.
    ellipse(blocation.x, blocation.y, 5, 5);
  }
}

void keyPressed() {
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
      //println("Game over");
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
