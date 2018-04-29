#import <AppKit/AppKit.h>
#import "EditWorld.h"

#define CPOINTSIZE	7		// size for clicking
#define CPOINTDRAW	4		// size for drawing

#define LINENORMALLENGTH	6	// length of line segment side normal
#define THINGDRAWSIZE		32

extern	BOOL	linecross[9][9];

@interface MapView: NSView
{
	float		scale;
	
	int		gridsize;
}

- (instancetype)initFromEditWorld;

- (float)currentScale;
- (NSPoint) getCurrentOrigin;

- (IBAction)scaleMenuTarget: sender;
- (IBAction)gridMenuTarget: sender;

- (void)zoomFrom:(NSPoint)origin toScale:(float)newscale;

- (void)displayDirty: (NSRect const *)dirty;

- (NSPoint) getPointFrom: (NSEvent const *)event;
- (NSPoint) getGridPointFrom: (NSEvent const *)event;

- (void)adjustFrameForOrigin: (NSPoint)org scale:(float)scl;
- (void)adjustFrameForOrigin: (NSPoint)org;
- (void)setOrigin: (NSPoint)org scale: (float)scl;
- (void)setOrigin: (NSPoint)org;

@end

// import category definitions

#import "MapViewDraw.h"
#import "MapViewResp.h"

