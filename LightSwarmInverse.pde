//FUTURE CITIES LAB
//Ripon DeLeon
//October 06, 2014

import processing.serial.*;
Serial yunPort; 

//BOOLEAN VARIABLES
boolean PIXELVIEW = false; //LOAD SECOND FRAME WITH PIXEL FACADE VIEW
boolean SHOW_DISPLAY = false; //ACTIVATE PIXEL DISPLAY keypress "shift" to toggle
boolean SHOW_SENSOR = false; //DISPLAY SESNORS keypress "s" to toggle
boolean SHOW_ATTRACTOR = false; // DISPLAY BOUNCE ATTRACTOR keypress "a" to toggle
boolean pixelate = true; //GENERATE PIXEL VALUES keypress "enter" to toggle (LEGACY)
boolean GRAVITATE = true; //ATTRACTOR or REPELLER keypress "g" to toggle
boolean ACTIVE = true; //ATTRACTOR or REPELLER keypress "g" to toggle


boolean SENSOR_DATA_FILE = false;
boolean SHOW_DATA_RATE = false;

//SHUTDOWN VARIABLES
int SHUTDOWN_HOUR = 02;//02;
int SHUTDOWN_MINUTE = 01;//01;
int STARTUP_HOUR = 05;//05;
int STARTUP_MINUTE = 01;//01;


//DISPLAY SETUP
int FacadePixelWidth = 119;
int FacadePixelHeight = 25;

int numPixelsWide, numPixelsHigh;
int blockSizeWidth = 5;//5
int blockSizeHeight = 10;//10

int block_scale = 10;
PFrame f_pixelate;
secondApplet s;
import java.awt.Frame;

//BOUNCE ATTRACTOR VARIABLES
int rad = 5;//1        // Width of the shape
float xpos, ypos;    // tarting position of shape    
int xbuffer = 15;

float speedMax = 1.5000;//4
float speedMin = 0.5000;//1
float speedXfactor = 8.000;//1.0
float speedYfactor = speedXfactor*2;//2


float xspeed = speedMax;//10;  // Speed of the shape
float yspeed = speedMin;//10;  // Speed of the shape


int xdirection = 1;  // Left or Right
int ydirection = 1;  // Top to Bottom


//float noiseScale=0.02;//0.02
float noiseVal = 4;

//SWARM VARIABLES
particle[] Z = new particle[10000];//10000
//float colour = random(1);
float colour = 0.5;
int blur_factor = 2;

//SENSOR

int sensor_loc[][] = {
  {
    100, 14
  }
  , 
  {
    78, 14
  }
  , 
  {
    60, 8
  }
  , 
  {
    46, 10
  }
  , 
  {
    35, 3
  }
  , 
  {
    35, 22
  }
  , 
  {
    25, 22
  }
  , 
  {
    17, 22
  }
};

float sensor_display[] = {
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
};

int sensor_color_index = 200;
int sensor_color_step = 1;
int sensor_color_max = 275;
int sensor_color_min = -25;
color sensor_color = color(125, 0, 255);
//FEEDBACK VARIABLES
PFont f;

//DATALOG

boolean RECORD = false;
PrintWriter output;
long write_count = 0;
long write_max = 1000;


void setup() {
  //smooth();

  size(FacadePixelWidth*blockSizeWidth, FacadePixelHeight*blockSizeHeight, P2D);

  background(255);
  frameRate(32);

  initializeSwarm();
  //PIXELATE

  numPixelsWide = width / blockSizeWidth;
  numPixelsHigh = height / blockSizeHeight;

  LightSwarmSetup();


  //feedback text

  f = createFont("Arial", 10);
  textFont(f);
  if (PIXELVIEW) {
    PFrame f_pixelate = new PFrame(width*block_scale, height*block_scale);
  }

  // SCALE SENSOR LOCATIONS
  for (int i = 0; i < sensor_loc.length; i++) {
    sensor_loc[i][0] =  sensor_loc[i][0] *blockSizeWidth;
    sensor_loc[i][1] =  sensor_loc[i][1] *blockSizeHeight;
  }
}

void draw() {
  SHUTDOWN_TEST();
  if (ACTIVE) {
    //BOUNCE
    // Update the position of the attractor
    xpos = xpos + ( xspeed * xdirection );
    ypos = ypos + ( yspeed * ydirection );

    //noiseVal = noise(xpos*noiseScale, ypos*noiseScale);

    xpos = xpos+sin(ypos)*random(0, noiseVal);
    ypos = ypos+cos(xpos)*random(0, noiseVal);

    // Test to see if the attractor exceeds the boundaries of the screen
    // If it does, reverse its direction by multiplying by -1
    if (xpos >= width-rad-xbuffer || xpos <= rad+xbuffer) {
      xdirection *= -1;
      xspeed = random(speedMin/speedXfactor, speedMax/speedXfactor);
    }
    if (ypos >= height-rad || ypos <= rad) {
      ydirection *= -1;
      yspeed = random(speedMin/speedYfactor, speedMax/speedYfactor);
    }
    xpos = constrain(xpos, rad+xbuffer, width-rad-xbuffer);
    ypos = constrain(ypos, rad, height-rad);

    if (SHOW_ATTRACTOR) {
      fill(255, 0, 0);
      ellipse(xpos, ypos, 5, 5);
    }
    //SWARM

    float r;

    //if( night )
    filter(INVERT);

    if ( pixelate ) {
      stroke(255, 100);
      fill(255, 100);
      rect(0, 0, width, height);
    } else {
      background(250);
    }
    //colour = color(sensor_color_index, 0, 255);

    colorMode(RGB, 255);

    //colorMode(HSB, 1);
    //colorMode(RGB, 1.0);

    for (int i = 0; i < Z.length; i++) {

      if (GRAVITATE) {
        Z[i].gravitate( new particle( xpos, ypos, 100, 0, 100 ) );
      } else {
        Z[i].repel( new particle( xpos, ypos, 0, 0, 10 ) );
      }
      
      Z[i].deteriorate();
      Z[i].update();
      //r = map(Z[i].magnitude/100, 0,1,.1,0.3);
      r = map(constrain(Z[i].magnitude,0,80), 0, 80, 191, 255);
      stroke(r,r, r);
     // }
      Z[i].display();
    }

    //colorMode(RGB, 255);

    //colour+=random(0.01);
    if ( colour > 1 ) { 
      colour = colour%1;
    }

    filter(INVERT);

    //PIXELATE
    PImage img = createImage(width, height, RGB);
    if ( pixelate ) {
      loadPixels();
      int pixel_index = 0;

      img.pixels = pixels;

      img.resize(numPixelsWide, numPixelsHigh);
      img.filter(BLUR, blur_factor);
      img.filter(DILATE);

      LightSwarmDisplay(img.pixels);

      if (SHOW_DISPLAY && PIXELVIEW) {

        for (int i = 0; i < img.pixels.length; i++) {
          s.movColors[i] = color(img.pixels[i]);
        }

        s.redraw();
      }
    } else {
      println(frameRate);
    }
    if (SHOW_SENSOR) {
      sensorDisplay();
    }

    fill(255);
    text(round(frameRate), width-15, 15);
  }
}

//INITIALIZING

void initializeSwarm() {

  //BOUNCE


  ellipseMode(RADIUS);
  // Set the starting position of the shape
  xpos = width/2;
  ypos = height/2;

  //SWARM
  float r;
  float phi;

  for (int i = 0; i < Z.length; i++) {

    r = sqrt( random( sq(width/2) + sq(height/2) ) );
    phi = random(TWO_PI);
    Z[i] = new particle( r*cos(phi)+width/2, r*sin(phi)+height/2, 0, 0, random(2.5)+0.5 );
  }

  //ARDUINO RELAY
  println(Serial.list());
  if (Serial.list().length > 0) {
    try {
      String portName = Serial.list()[5];
      yunPort = new Serial(this, portName, 9600);
      yunPort.write('B');
    }
    catch (Exception e) {
      e.printStackTrace();
    }
  }
}



//SWARM INTERACTION METHODS
void scatter(int x, int y) {
  xpos = x; 
  ypos = y; 
  xspeed = max(xspeed/2, speedMin);
  yspeed = max(yspeed/2, speedMin);
}

void pull(int x, int y) {
  float xDelta;
  float yDelta;
  if (x > xpos) {
    xDelta = x - xpos;
    xdirection = 1;
  } else {
    xDelta = xpos- x;
    xdirection = -1;
  }
  if (y > ypos) {
    yDelta = y - ypos;
    ydirection = 1;
  } else {
    yDelta = ypos- y; 
    ydirection = -1;
  }

  xspeed = (xDelta/(xDelta+yDelta));
  yspeed = (yDelta/(xDelta+yDelta));
  //  print("xspeed > ");
  //  print(xspeed);
  //  print(" | yspeed > ");
  //  println(yspeed);
  if (xspeed > yspeed) {
    yspeed = (speedMax/xspeed)*yspeed;
    xspeed = speedMax;
    //  print("xspeed > ");
    //  print(xspeed);
    //  print(" | yspeed > ");
    //  println(yspeed);
  } else {
    xspeed = (speedMax/yspeed)*xspeed;
    yspeed = speedMax;    
    //  print("xspeed > ");
    //  print(xspeed);
    //  print(" | yspeed > ");
    //  println(yspeed);
  }
}

//SENSOR METHODS
void sensorDisplay() {
  int sensor_radius = 5;
  float sensor_val;
  sensor_color_index += sensor_color_step;

  if (sensor_color_index == sensor_color_max) //275 
    sensor_color_step *= -1;
  else if (sensor_color_index == sensor_color_min) //-25
    sensor_color_step *= -1;

  sensor_color = color(sensor_color_index, 0, 255);

  for (int i = 0; i < Sensor.length; i++) {
    if (sensor_display[i] > 0) {
      //fill(sensor_color_index, 0, 255, int(map(getSensorValue(i), 0, 600, 0, 255)));
      //filter(INVERT);
      noStroke();
      sensor_val = sensor_display[i];
      //filter(INVERT);
      fill(sensor_color, int(map(constrain(sensor_val, 0, 10), 0, 10, 0, 255)));
      ellipse(sensor_loc[i][0], sensor_loc[i][1], sensor_radius, sensor_radius);
      sensor_val -= 1;
    }
    sensor_display[i] -= 0.15;
  }
}

//UI METHODS


void keyPressed() {
  if ( keyCode == ENTER ) {
    pixelate = !pixelate;
    background(255);
  }
  if ( keyCode == SHIFT ) {
    SHOW_DISPLAY = !SHOW_DISPLAY;
  }
  if ( key == 's' ) {
    SHOW_SENSOR = !SHOW_SENSOR;
  }
  if ( key == 'a' ) {
    SHOW_ATTRACTOR = !SHOW_ATTRACTOR;
  } 
  if ( key == 'g' ) {
    GRAVITATE = !GRAVITATE;
  }
  if ( key == 'r' ) {
    if (!RECORD) {
      RECORD = !RECORD;
      startRecording();
    }
  }
}

void mousePressed() {
  if (mouseButton == LEFT) {
    //scatter(mouseX, mouseY);
    pull(mouseX, mouseY);
  } else if (mouseButton == RIGHT) {
    pull(mouseX, mouseY);
  }
}


//TIMED METHODs
void SHUTDOWN_TEST() {
  //if (hour() == SHUTDOWN_HOUR && minute() == SHUTDOWN_MINUTE) {
  //if (ACTIVE) {
  if (hour() == SHUTDOWN_HOUR && minute() == SHUTDOWN_MINUTE && ACTIVE) {
    ACTIVE = false;
    udp.dispose();
    udp.close();
    if (Serial.list().length > 0) {
      try {

        yunPort.write('Q');
        yunPort.clear();
        yunPort.stop();
      }
      catch (Exception e) {
        e.printStackTrace();
      }
    }

    println("GOODNIGHT");
    //exit();
  } else if (hour() == STARTUP_HOUR && minute() == STARTUP_MINUTE && !ACTIVE) {
    ACTIVE = true;

    println("GOODMORNING");
    //initializeSwarm();
    LightSwarmSetup();
    if (Serial.list().length > 0) {
      try {
        String portName = Serial.list()[5];
        yunPort = new Serial(this, portName, 9600);
        yunPort.write('B');
        
      }
      catch (Exception e) {
        e.printStackTrace();
      }
    }
  }

  if (minute() % 30 == 0) {
    if (!RECORD) {
      RECORD = !RECORD;
      startRecording();
    }
  }
}

void startRecording() {
  String filename = "sensorRecords/Sounds_" + month() + "_" + day() + "_" + year() + "_" + hour() + "_" + minute() + "_" + second() + ".txt" ;
  output = createWriter(filename);
  println("RECORD ON");
}

//PIXELATED FRAME CLASS AND METHODS
public class PFrame extends Frame {
  public PFrame() {
    setBounds(100, 100, 400, 300);
    s = new secondApplet();
    add(s);
    s.init();
    show();
  }

  public PFrame(int w, int h) {
    setBounds(700, 100, w, h);
    s = new secondApplet();
    add(s);
    s.init();
    show();
  }
}

public class secondApplet extends PApplet {
  PImage img;
  int numPixelsHigh = 25;
  int numPixelsWide = 119;
  int blockSizeWidth = 10;
  int blockSizeHeight = 20;

  color movColors[];

  public void setup() {
    size(numPixelsWide*blockSizeWidth, numPixelsHigh*blockSizeHeight);
    //size(width,height);
    noLoop();
    //img = loadImage("ny.jpg");
    movColors = new color[numPixelsWide * numPixelsHigh];
  }


  public void draw() {
    background(0);
    int alpha = 255;
    float red = 0;
    float green =0;
    float blue = 0;
    //int lower = round(led_base);
    int lower = 50;
    
    for (int j = 0; j < numPixelsHigh; j++) {
      for (int i = 0; i < numPixelsWide; i++) {
        if (Pixel_Map[j*numPixelsWide + i] > -1) {
          //fill((movColors[j*numPixelsWide + i] >>16) & 0xFF, (movColors[j*numPixelsWide + i] >>8) & 0xFF, movColors[j*numPixelsWide + i] & 0xFF, 255) ;// 
          alpha = 255;
          red = red(movColors[j*numPixelsWide + i]);
          green = green(movColors[j*numPixelsWide + i]);
          blue = blue(movColors[j*numPixelsWide + i]);

          if (red < lower) {
            red = 0;
          }
          if (blue < lower) {
            blue = lower;
          }
          if (green < lower) {
            green = lower;
          }
        } else {
          //fill(color(125,0,0),255);
          red = 0;
          green = 0;
          blue = 0;
          alpha = 25;
        }
        //fill((movColors[j*numPixelsWide + i] >>16) & 0xFF, (movColors[j*numPixelsWide + i] >>8) & 0xFF, movColors[j*numPixelsWide + i] & 0xFF, alpha) ;
        fill(red, green, blue, alpha);
        rect(i*blockSizeWidth, j*blockSizeHeight, blockSizeWidth, blockSizeHeight);
      }
    }
  }
}
