/* OpenProcessing Tweak of *@*http://www.openprocessing.org/sketch/2799*@* */
/* !do not delete the line above, required for linking your tweak if you upload again */
// Gravity Swarm II
// Claudio Gonzales, July 2009
// Albuquerque, New Mexico

class particle {
  
  float x;
  float y;
  float px;
  float py;
  float magnitude;
  float angle;
  float mass;
  float speed_factor = random(.006,.04); //.006,.02//,01,.08
  
  
  particle( float dx, float dy, float V, float A, float M ) {
    x = dx;
    y = dy;
    px = dx;
    py = dy;
    magnitude = V;
    angle = A;
    mass = M;
  }
  
  void reset( float dx, float dy, float V, float A, float M ) {
    x = dx;
    y = dy;
    px = dx;
    py = dy;
    magnitude = V;
    angle = A;
    mass = M;
  }
  
  void gravitate( particle Z ) {
    float F, mX, mY, A;
    if( sq( x - Z.x ) + sq( y - Z.y ) != 0 ) {
      F = mass * Z.mass;
      F /= sqrt( sq( x - Z.x ) + sq( y - Z.y ) );
      //F /= ( sq( x - Z.x ) + sq( y - Z.y ) );
      if( sqrt(sq( x - Z.x ) + sq( y - Z.y )) < 10 ) {
        F = 0.1;
      }
      mX = ( mass * x + Z.mass * Z.x ) / ( mass + Z.mass );
      mY = ( mass * y + Z.mass * Z.y ) / ( mass + Z.mass );
      A = atan2( mY-y, mX-x );
      
      mX = F * cos(A);
      mY = F * sin(A);
      
      mX += magnitude * cos(angle);
      mY += magnitude * sin(angle);
      
      magnitude = sqrt( sq(mX) + sq(mY) )*1.05;//1.05
      angle = findAngle( mX, mY );
    }
  }

  void repel( particle Z ) {
    float F, mX, mY, A;
    if( sq( x - Z.x ) + sq( y - Z.y ) != 0 ) {
      F = mass * Z.mass;
      F /= sqrt( sq( x - Z.x ) + sq( y - Z.y ) );
      if( sqrt(sq( x - Z.x ) + sq( y - Z.y )) < 10 ) {
        F = 0.1;
      }
      mX = ( mass * x + Z.mass * Z.x ) / ( mass + Z.mass );
      mY = ( mass * y + Z.mass * Z.y ) / ( mass + Z.mass );
      A = atan2( y-mY, x-mX );
      
      mX = F * cos(A);
      mY = F * sin(A);
      
      mX += magnitude * cos(angle);
      mY += magnitude * sin(angle);
      
      magnitude = sqrt( sq(mX) + sq(mY) );
      angle = findAngle( mX, mY );
    }
  }
  
  void deteriorate() {
    magnitude *= 0.9;//0.9;
  }
  
  void update() {
    
    x += magnitude * cos(angle)* speed_factor;
    y += magnitude * sin(angle)* speed_factor;
    
  }
  
  void display() {
    line(px,py,x,y);
    px = x;
    py = y;
  }
  
  
}


float findAngle( float x, float y ) {
  float theta;
  if(x == 0) {
    if(y > 0) {
      theta = HALF_PI;
    }
    else if(y < 0) {
      theta = 3*HALF_PI;
    }
    else {
      theta = 0;
    }
  }
  else {
    theta = atan( y / x );
    if(( x < 0 ) && ( y >= 0 )) { theta += PI; }
    if(( x < 0 ) && ( y < 0 )) { theta -= PI; }
  }
  return theta;
}
 
