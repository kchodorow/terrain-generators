#import <Foundation/Foundation.h>
#import "CC3Foundation.h"

#ifndef CHECK
#define CHECK(x) NSAssert(x, @#x)
#endif
#ifndef cc3p
#define cc3p(x, y) CC3IntPointMake((x), (y))
#endif

@interface HillTerrain : NSObject {

@private
  float _hill_min;
  float _hill_max;
  unsigned short _num_hills;
  unsigned short _flattening;
  bool _island;
  unsigned int _seed;

  float *_map; // buffer of cells
}

// Initializes terrain which defaults to:
// * Size of 256x128
// * 200 hills
// * Min hill radius: 2
// * Max hill radius: 40
// * Flattening factor of 1
// * Not an island
// * Seed of 12345
- (id) init;

// Initializes terrain with a custom size.
- (id) init:(CC3IntSize)size;

// Smallest possible radius for a hill.
// Range: 0.0 to fHillMax
- (void) setHillMin:(float)min;

// Largest possible radius for a hill.
// Range: fHillMax or greater
- (void) setHillMax:(float)max;

// Number of hills to add to the terrain when generated.
// Range: any
- (void) setNumHills:(int)num;

// Power to raise heightmap values to to flatten. 1 is no flattening. Increasing
// this number very dramatically distorts the map.
// Range: 1 or greater
- (void) setFlattening:(int)power;

// True if hills should be positioned to create an island. If so, the edge of
// the heightmap will always reach 0.0, otherwise, hills will be placed randomly
// distributed across the heightmap.
- (void) setIsland:(BOOL)isIsland;

// The value to seed the random number generator with before generating. change
// this to create different terrains. store it to be able to recreate a terrain.
- (void) setSeed:(unsigned int)seed;

// Clears, regenerates, normalizes, and flattens the terrain using the current
// parameters. Unless the seed is changed, this will generate the same terrain
// every time. Call this after setting the parameters to create a terrain. All
// heights generated will be between 0 and 1.
- (void) generate;

// Returns the heightmap.
- (float*) map;

// Gets a specific height from the hieghtmap.
- (float) getCell:(CC3IntPoint)xy;

// Deallocates the heightmap and destructs the terrain.
- (void) dealloc;

@property CC3IntSize size;

@end
