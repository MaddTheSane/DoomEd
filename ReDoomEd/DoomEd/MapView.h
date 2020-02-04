// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

#import "EditWorld.h"

#define CPOINTSIZE	7		// size for clicking
#define CPOINTDRAW	4		// size for drawing

#define LINENORMALLENGTH	6	// length of line segment side normal
#define THINGDRAWSIZE		32

extern	BOOL	linecross[9][9];

@interface MapView: View
{
	float		scale;
	
	int		gridsize;
}

- (instancetype)initFromEditWorld;

@property (readonly) float currentScale;
- getCurrentOrigin: (NXPoint *)worldorigin;

- (IBAction)scaleMenuTarget: sender;
- (IBAction)gridMenuTarget: sender;

- zoomFrom:(NXPoint *)origin toScale:(float)newscale;

- displayDirty: (NXRect const *)dirty;

- getPoint:	(NXPoint *)point  from: 	(NXEvent const *)event;
- getGridPoint:	(NXPoint *)point  from: 	(NXEvent const *)event;

- adjustFrameForOrigin: (NXPoint const *)org scale:(float)scl;
- adjustFrameForOrigin: (NXPoint const *)org;
- setOrigin: (NXPoint const *)org scale: (float)scl;
- setOrigin: (NXPoint const *)org;

@end

// import category definitions

#import "MapViewDraw.h"
#import "MapViewResp.h"

