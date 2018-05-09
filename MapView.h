#import <AppKit/AppKit.h>
#import "EditWorld.h"

#define CPOINTSIZE	7		// size for clicking
#define CPOINTDRAW	4		// size for drawing

#define LINENORMALLENGTH	6	// length of line segment side normal
#define THINGDRAWSIZE		32

extern	BOOL	linecross[9][9];

@interface MapView: NSView
{
	CGFloat		scale;
	
	int		gridsize;
}

- (instancetype)initFromEditWorld;

@property (readonly) CGFloat currentScale;
- (NSPoint) getCurrentOrigin;

- (IBAction)scaleMenuTarget: sender;
- (IBAction)gridMenuTarget: sender;

- (void)zoomFrom:(NSPoint)origin toScale:(CGFloat)newscale;

- (void)displayDirty: (NSRect)dirty;

- (NSPoint) getPointFrom: (NSEvent const *)event;
- (NSPoint) getGridPointFrom: (NSEvent const *)event;

- (void)adjustFrameForOrigin: (NSPoint)org scale:(CGFloat)scl;
- (void)adjustFrameForOrigin: (NSPoint)org;
- (void)setOrigin: (NSPoint)org scale: (CGFloat)scl;
- (void)setOrigin: (NSPoint)org;

@end
