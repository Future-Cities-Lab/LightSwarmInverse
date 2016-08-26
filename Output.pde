
import hypermedia.net.*;

//BOOLEAN VARIABLES


//LED DISPLAY VARIABLES

int[] Pixel_Map;
color lightSwarmColors[];

int led_base_min = 22;
int led_base_max = 35;
float led_base_step = 0.25;
float led_base = led_base_min;
int led_max = 220;

int FIRST_LED_COUNT = 207; //207
int SECOND_LED_COUNT = 221; //221
int N_LEDS = FIRST_LED_COUNT + SECOND_LED_COUNT; // Max of 65536

//SENSOR VARIABLES

byte Sensor[] = {
  'A', 'E', 'I', 'J', 'P', 'Q', 'R', 'S'
};

int SENSOR_SMOOTH_LENGTH = 5;
int SENSOR_DATA[][] = new int[Sensor.length][SENSOR_SMOOTH_LENGTH];
int SENSOR_POINTER[] = new int[Sensor.length];
int SENSOR_VALUE[] = new int[Sensor.length];
boolean SENSOR_EVENT[] = new boolean[Sensor.length];

int SENSOR_ACTIVE_EVENT = 0;
int SENSOR_MAJOR_THRESHOLD = 3;

float sensor_trigger_factor = 0.90;

int sensor_index = 0; //next sensor to request
int sensor_request = 0;  //count between sensor requests
int sensor_request_index = 0; //index counter for next sensor request


//UDP VARIABLES
UDP udp;  // define the UDP object
String ip = "192.168.1.255";
int frameDelay = 10;

int port = 8888;    // the destination port


byte[] buffer = new byte[N_LEDS * 3];
byte[] bufferAintro= new byte[2];
byte[] bufferBintro= new byte[2];


byte[] bufferA = new byte[FIRST_LED_COUNT * 3 + bufferAintro.length];
byte[] bufferB = new byte[SECOND_LED_COUNT * 3 + bufferBintro.length];



int    t, prev, frame = 0;
long   totalBytesSent = 0;

//SENSOR FILE VARIABLES

int sensor_read_index = 30;
int[][] Stored_Sensor_Data;




void LightSwarmSetup() {
  String[] lines = loadStrings("Pixel_Map.csv");
  Pixel_Map = int(splitTokens(lines[0], ","));
  lightSwarmColors = new color[FIRST_LED_COUNT + SECOND_LED_COUNT];
  sensorSetup();

  if (SENSOR_DATA_FILE) {
    readSensorFromFile();
  }

  udp = new UDP( this, 6000 );  // create a new datagram connection on port 6000
  //udp.log( true );     // <-- printout the connection activity
  udp.listen( true );  
  udp.broadcast(true);

  bufferAintro[0] = '!'; 
  bufferBintro[0] = '@';


  prev  = second(); // For bandwidth statistics
} 



void LightSwarmDisplay(color display[]) {
  float red;
  float blue;
  float green;
  int lower = round(led_base);

  led_base += led_base_step;
  if (led_base >= led_base_max) {
    led_base_step = led_base_step * -1;
  } 
  else if (led_base <= led_base_min) {
    led_base_step = led_base_step * -1;
  }
  for (int i = 0; i < display.length; i++) {

    if (Pixel_Map[i] > -1) { 
      //buffer[Pixel_Map[i]*3]= byte((display[i] >> 16) & 0xFF); //bit shift red
      //buffer[(Pixel_Map[i]*3)+1]= byte((display[i] >> 8) & 0xFF); //bit shift green
      //buffer[(Pixel_Map[i]*3)+2]= byte(display[i] & 0xFF); //bit shift 

      //Set minimum brightness values
      red = (display[i] >> 16) & 0xFF;//red(display[i]);
      green = (display[i] >> 8) & 0xFF;//blue(display[i]);
      blue = display[i] & 0xFF;//green(display[i]);
//      if (red < lower) {
//        red = lower;
//      }
//      if (blue < lower) {
//        blue = lower;
//      }
//      if (green < lower) {
//        green = lower;
//      }
      red = constrain(red, 0, led_max);
      //green = constrain(green, lower, led_max);
      green = constrain(green, max(lower-red,0), led_max);
      blue = constrain(blue, lower, led_max);

      buffer[Pixel_Map[i]*3]= byte(red); //bit shift red
      buffer[(Pixel_Map[i]*3)+1]= byte(green); //bit shift green
      buffer[(Pixel_Map[i]*3)+2]= byte(blue); //bit shift
      if (i == 270) {
//       print(int(red));
//       print(',');
//       print(int(green));
//       print(',');
//       println(int(blue));
//       print(byte(red));
//       print(',');
//       print(byte(green));
//       print(',');
//       println(byte(blue));
      }
    }
  }

  //assemble UDP header
  bufferAintro[0] = '!'; 
  bufferBintro[0] = '@';

  bufferAintro[1] = 'Z'; //no sensor reply 
  if (sensor_request_index >= sensor_request) {
    bufferBintro[1] = Sensor[sensor_index];
    sensor_index += 1;
    sensor_request_index = 0;
    if (sensor_index >= Sensor.length) {
      sensor_index = 0;
    }
  } 
  else {
    bufferBintro[1] = 'Z'; //no sensor reply
    sensor_request_index += 1;
  }

  //create seperate UDP messages
  bufferA = concat(bufferAintro, subset(buffer, 0, FIRST_LED_COUNT * 3));
  bufferB = concat(bufferBintro, subset(buffer, FIRST_LED_COUNT * 3));
  udp.send(bufferA, ip, port);
  delay(frameDelay);
  udp.send(bufferB, ip, port);

  totalBytesSent += buffer.length+bufferAintro.length+bufferBintro.length;
  frame++;

  // Update statistics once per second
  if ((t = second()) != prev) {
    if (SHOW_DATA_RATE) {
      print("Average frames/sec: ");
      //print(int((float)frame / (float)millis() * 1000.0));
      print(frame);
      print(", bytes/sec: ");
      println(int((float)totalBytesSent / (float)millis() * 1000.0));
    }
    prev = t; 
    frame = 0;
  }


  if (SENSOR_DATA_FILE) {
    sensorFileStep();
  }
}

void readSensorFromFile() {

  String[] lines = loadStrings("sensor_data.txt");
  Stored_Sensor_Data = new int[lines.length][];
  for (int i = 0; i < lines.length; i++) {
    Stored_Sensor_Data[i]= int(splitTokens(lines[i], ","));
  }
}



void sensorFileStep() {
  setSensorData(Stored_Sensor_Data[sensor_read_index]);
  sensor_read_index += 1;
  if (sensor_read_index >= Stored_Sensor_Data.length) {
    sensor_read_index = 0;
  }
  if (RECORD)
    recordSensor2File("test" + sensor_read_index);
}


void sensorSetup() {
  int SENSOR_DATA[][] = new int[Sensor.length][SENSOR_SMOOTH_LENGTH];
  int SENSOR_POINTER[] = new int[Sensor.length];
  for (int i = 0; i < Sensor.length; i++) {
    SENSOR_POINTER[i] = 0;
    SENSOR_VALUE[i] = 0;
    SENSOR_EVENT[i] = false;
    for (int j = 0; j < SENSOR_SMOOTH_LENGTH; j++) {
      SENSOR_DATA[i][j] =0;
    }
  }
}

void setSensorData (int[] sensor_val) {
  int read_val = 2;
  int sensor_id = sensor_id_simplify(sensor_val[0]);

  SENSOR_EVENT[sensor_id] = sensor_event(sensor_id, sensor_val[read_val]);
  SENSOR_VALUE[sensor_id] -= SENSOR_DATA[sensor_id][SENSOR_POINTER[sensor_id]]; 
  SENSOR_VALUE[sensor_id] += sensor_val[read_val];
  SENSOR_DATA[sensor_id][SENSOR_POINTER[sensor_id]] = sensor_val[read_val];
  SENSOR_POINTER[sensor_id] += 1;
  if (SENSOR_POINTER[sensor_id] >= SENSOR_SMOOTH_LENGTH) {
    SENSOR_POINTER[sensor_id] = 0;
  }
}

int getSensorValue(int sensor_id) {
  return round(SENSOR_VALUE[sensor_id]/SENSOR_SMOOTH_LENGTH);
} 


int sensor_id_simplify(int temp) {
  switch(temp) {
  case 0:
    return 0;
  case 4:
    return 1;
  case 8:
    return 2;
  case 9:
    return 3;
  case 15:
    return 4;
  case 16:
    return 5;
  case 17:
    return 6;
  case 18:
    return 7;
  }
  return -1;
}

boolean sensor_event(int sensor_id, int current_val) {

  //if ((current_val * (1-sensor_trigger_factor)) > getSensorValue(sensor_id)) {
  if (current_val - getSensorValue(sensor_id) > 300) {
//    print(sensor_id);
//    print(" --> ");
//    print(current_val);
//    print(" > ");
//    println(getSensorValue(sensor_id));
    if (!SENSOR_EVENT[sensor_id])
      SENSOR_ACTIVE_EVENT +=1;
    //if (SENSOR_MAJOR_EVENT()) {
    //   scatter(sensor_loc[sensor_id][0],sensor_loc[sensor_id][1]);
    //} else {
    pull(sensor_loc[sensor_id][0], sensor_loc[sensor_id][1]);
    float temp_val = map(constrain(current_val, 300, 900), 300, 900, 0, 10.0);
    if (temp_val > sensor_display[sensor_id])
      sensor_display[sensor_id] = temp_val;
    // }
    return true;
  } 
  else {
    if (SENSOR_EVENT[sensor_id])
      SENSOR_ACTIVE_EVENT -=1;
    return false;
  }
}

boolean SENSOR_MAJOR_EVENT() {
  if (SENSOR_ACTIVE_EVENT >= SENSOR_MAJOR_THRESHOLD) 
    return true;
  else
    return false;
}

void receive( byte[] data, String ip, int port ) {  // <-- extended handler
  SENSOR_DATA_FILE = false;
  String temp[] = new String[4];

  String message = new String( data );

  //println( "receive: \""+message+"\" from "+ip+" on port "+port );

  setSensorData(int(splitTokens(message, ",")));
  if (RECORD)
    recordSensor2File(message);
}

void recordSensor2File(String message) {
  output.print(message);
  output.print(",");
  output.print(millis());
  output.print(",");
  output.print(hour());
  output.print(",");
  output.print(minute());
  output.print(",");
  output.println(second());
  if (write_count > write_max) {
    output.flush(); // Write the remaining data
    output.close(); // Finish the file
    println("RECORD OFF");
    RECORD = false;
    write_count = 0;
  } 
  else {
     write_count +=1;
  }
}
