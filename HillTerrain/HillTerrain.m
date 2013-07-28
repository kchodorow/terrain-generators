#import "HillTerrain.h"

@implementation HillTerrain

- (id) init {
  return [self init:CC3IntSizeMake(256, 128)];
}

- (id) init:(CC3IntSize)size {
  self = [super init];

  if (self) {
    _size = size;
    _hill_min = 2.0;
    _hill_max = 40.0;
    _num_hills = 200;
    _flattening = 1;
    _island = false;
    _seed = 12345;
  }

  return self;
}

- (void) setHillMin:(float)min {
  CHECK(min >= 0.0);
  CHECK(min < _hill_max);
  _hill_min = min;
}

- (void) setHillMax:(float)max {
  CHECK(max >= 0.0);
  CHECK(_hill_min < max);
  _hill_max = max;
}

- (void) setNumHills:(int)num {
  _num_hills = num;
}

- (void) setFlattening:(int)power {
  CHECK(power > 0);
  _flattening = power;
}

- (void) setIsland:(BOOL)isIsland {
  _island = isIsland;
}

- (void) setSeed:(unsigned int)seed {
  _seed = seed;
}

- (void) dealloc {
  free(_map);
  [super dealloc];
}

- (void) generate {
  _map = (float*)malloc(_size.width * _size.height);
  CHECK(_map);

  [self clear];

  // set the seed
  srand(_seed);

  // add as many hills as needed
  for (int i = 0; i < _num_hills; ++i) {
    [self addHill];
  }

  // now clean it up
  [self normalize];
  [self flatten];
}

- (float*) map {
  return _map;
}


// Clear
// ----------------------------------------------------------------------------
- (void) clear {
  // make sure there is a terrain
  CHECK(_map != NULL);

  for( int x = 0; x < _size.width; ++x ) {
    for( int y = 0; y < _size.height; ++y ) {
      [self setCell:cc3p(x,y) value:0];
    }
  }
}


// AddHill
// ----------------------------------------------------------------------------
-(void) addHill {
  // make sure there is a terrain
  CHECK(_map != NULL);

  // pick a size for the hill
  float fRadius = [self randomRange:_hill_min max:_hill_max];

  // pick a centerpoint for the hill
  float x, y;
  if (_island) {
    // this determines in which direction from the center of the map the
    // hill will be placed.
    float fTheta = [self randomRange:0 max:6.28];

    // this is how far from the center of the map the hill be placed. note
    // that the radius of the hill is subtracted from the range to prevent
    // any part of a hill from reaching the very edge of the map.
    float fDistanceX = [self randomRange:fRadius/2 max:(_size.width/2 - fRadius)];
    float fDistanceY = [self randomRange:fRadius/2 max:(_size.height/2 - fRadius)];

    // converts theta and a distance into x and y coordinates.
    x = _size.width/2.0 + cos( fTheta ) * fDistanceX;
    y = _size.height/2.0 + sin( fTheta ) * fDistanceY;
  } else {
    // note that the range of the hill is used to determine the
    // centerpoint. this allows hills to have their centerpoint off the
    // edge of the terrain as long as part of the hill is in bounds. this
    // makes the terrains appear continuous all the way to the edge of the
    // map.
    x = [self randomRange:-fRadius max:(_size.width + fRadius)];
    y = [self randomRange:-fRadius max:(_size.height + fRadius)];
  }

  // square the hill radius so we don't have to square root the distance
  float fRadiusSq = fRadius * fRadius;
  float fDistSq;
  float fHeight;

  // find the range of cells affected by this hill
  int xMin = x - fRadius - 1;
  int xMax = x + fRadius + 1;
  // don't affect cell outside of bounds
  if( xMin < 0 ) xMin = 0;
  if( xMax >= _size.width ) xMax = _size.width;

  int yMin = y - fRadius - 1;
  int yMax = y + fRadius + 1;
  // don't affect cell outside of bounds
  if( yMin < 0 ) yMin = 0;
  if( yMax >= _size.height ) yMax = _size.height;

  // for each affected cell, determine the height of the hill at that point
  // and add it to that cell
  for (int h = xMin; h < xMax; ++h) {
    for (int v = yMin; v < yMax; ++v) {
      // determine how far from the center of the hill this point is
      fDistSq = ( x - h ) * ( x - h ) + ( y - v ) * ( y - v );
      // determine the height of the hill at this point
      fHeight = fRadiusSq - fDistSq;

      // don't add negative hill values (i.e. outside the hill's radius)
      if( fHeight > 0 ) {
	      // add the height of this hill to the cell
	      [self offsetCell:cc3p(h,v) value:fHeight];
	    }
    }
  }
}


// Normalize
// ----------------------------------------------------------------------------
- (void) normalize {
  // make sure there is a terrain
  CHECK(_map != NULL);

  float fMin = [self getCell:cc3p(0,0)];
  float fMax = [self getCell:cc3p(0,0)];

  // find the min and max
  for (int x = 0; x < _size.width; ++x) {
    for (int y = 0; y < _size.height; ++y) {
      float z = [self getCell:cc3p(x,y)];
      if( z < fMin ) fMin = z;
      if( z > fMax ) fMax = z;
    }
  }

  // If the min and max are the same, then the terrain has no height, so just
  // clear it to 0.0.
  if (fMax == fMin) {
    [self clear];
  }

  // Divide every height by the maximum to normalize to (0.0, 1.0).
  for (int x = 0; x < _size.width; ++x) {
    for (int y = 0; y < _size.height; ++y) {
      [self setCell:cc3p(x,y)
              value:([self getCell:cc3p(x,y)] - fMin ) / ( fMax - fMin )];
    }
  }
}


// Flatten
// ----------------------------------------------------------------------------
- (void) flatten {
  // make sure there is a terrain
  CHECK(_map != NULL);

  // If flattening is one, then nothing would be changed, so just skip the
  // process altogether.
  if (_flattening == 1) {
    return;
  }

  for (int x = 0; x < _size.width; ++x) {
    for (int y = 0; y < _size.height; ++y) {
      float fFlat  = 1.0;
      float fOriginal = [self getCell:cc3p(x,y)];

      // flatten as many times as desired
      for( int i = 0; i < _flattening; ++i ) {
        fFlat *= fOriginal;
      }

      // put it back into the cell
      [self setCell:cc3p(x,y) value:fFlat];
    }
  }
}


// RandomRange
// ----------------------------------------------------------------------------
- (float) randomRange:(float)min max:(float)max {
  return (rand() * (max - min) / RAND_MAX) + min;
}

// SetCell
// ----------------------------------------------------------------------------
- (void) setCell:(CC3IntPoint)pos value:(float)value {
  // make sure we have a terrain
  CHECK(_map != NULL);

  // check the parameters
  CHECK((pos.x >= 0) && (pos.x < _size.width));
  CHECK((pos.y >= 0) && (pos.y < _size.height));

  if (value < 0) {
    value = 0;
  }
  // set the cell
  _map[pos.x + (pos.y * _size.width)] = value;
}


// OffsetCell
// ----------------------------------------------------------------------------
- (void) offsetCell:(CC3IntPoint)pos value:(float)value {
  // make sure we have a terrain
  CHECK(_map != NULL );

  // check the parameters
  CHECK((pos.x >= 0) && (pos.x < _size.width));
  CHECK((pos.y >= 0) && (pos.y < _size.height));

  // offset the cell
  _map[pos.x + (pos.y * _size.width)] += value;
}

// GetCell
// ----------------------------------------------------------------------------
- (float) getCell:(CC3IntPoint)pos {
  // make sure we have a terrain
  CHECK(_map != NULL);

  // check the parameters
  CHECK((pos.x >= 0) && (pos.x < _size.width));
  CHECK((pos.y >= 0) && (pos.y < _size.height ));

  int index = pos.x + (pos.y * _size.width);
  if (_map[index] < 0) {
    return 0;
  }
  return _map[index];
}

@end
