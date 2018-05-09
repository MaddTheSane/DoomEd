#import "MapView.h"
#import "MapWindow.h"
#import "PreferencePanel.h"
#import "Timing.h"
#import "ToolPanel.h"
#import "SettingsPanel.h"
#import "Coordinator.h"
#import "pathops.h"
#include <ctype.h>

// import category definitions

#import "MapViewDraw.h"
#import "MapViewResp.h"


// some arrays are shared by all mapview for temporary drawing data

BOOL	linecross[9][9];

#define MAXPOINTS	200

@implementation MapView

+ (void) initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	int x1, y1, x2, y2;

	for (x1 = 0; x1 < 3 ; x1++)
	{
		for (y1 = 0; y1 < 3 ; y1++)
		{
			for (x2 = 0; x2 < 3 ; x2++)
			{
				for (y2 = 0; y2 < 3 ; y2++)
				{
					if  ( ( (x1<=1 && x2>=1) || (x1>=1 && x2<=1) ) 
					&& ( (y1<=1 && y2>=1) || (y1>=1 && y2<=1) ) )
						linecross[y1*3+x1][y2*3+x2] = YES;
					else
						linecross[y1*3+x1][y2*3+x2] = NO;
				}
			}
		}
	}
	});
}


/*
==================
=
= initFromEditWorld
=
==================
*/

-(instancetype)initFromEditWorld
{
	NSRect	aRect;

	// call -setOrigin after installing in clip view
	aRect = NSMakeRect(0, 0, 100, 100);
	if (self = [super initWithFrame: aRect]) {	// to set the proper rectangle
		if (![editworld_i loaded]) {
			NSRunAlertPanel(@"Error",
							@"MapView inited with NULL world",
							nil, nil, nil);
			[self release];
			return nil;
		}

		gridsize = 8;		// these are changed by the pop up menus
		scale = 1;
	}
	return self;
}

- (BOOL)isOpaque
{
	return YES;
}

#define TESTOPS	1000

- (IBAction)testSpeed:(id)sender
{
#if 0
        id 		t4;
	NXStream	*stream;
	int		i;

        t4 = [Timing newWithTag:4];

	stream = NXOpenMemory (NULL, 0, NX_WRITEONLY);

printf ("Display\n");
	[t4 reset];
	for (i=0 ; i<10 ; i++)
	{
		[t4 enter: WALLTIME];
		[self display];
		[t4 leave];
	}
	[t4 summary: stream];
printf ("No flush\n");
	[t4 reset];
	[[self window] disableFlushWindow];
	for (i=0 ; i<10 ; i++)
	{
		[t4 enter: WALLTIME];
		[self display];
		[t4 leave];
	}
	[[self window] reenableFlushWindow];
	[t4 summary: stream];

	NXSaveToFile (stream, "/aardwolf/Users/johnc/timing.txt");
	NXClose (stream);
printf ("Done\n");
#endif
}

/*
=====================
=
= worldBoundsChanged
=
= adjust the frame rect and redraw scalers
=
=====================
*/

- (void)worldBoundsChanged
{
	
}



/*
====================
=
= scaleMenuTarget:
=
= Called when the scaler popup on the window is used
=
====================
*/

- (IBAction)scaleMenuTarget: sender
{
	NSString	*item;
	float		nscale;
	NSRect		visrect;

	item = [sender titleOfSelectedItem];
	sscanf([item UTF8String], "%f", &nscale);
	nscale /= 100;

	if (nscale == scale)
		return;

	// try to keep the center of the view constant
	visrect = [[self superview] visibleRect];
	visrect = [self convertRect: visrect fromView: [self superview]];
	visrect.origin.x += visrect.size.width/2;
	visrect.origin.y += visrect.size.height/2;

	[self zoomFrom: visrect.origin toScale: nscale];
}


/*
====================
=
= gridMenuTarget:
=
= Called when the scaler popup on the window is used
=
====================
*/

- (IBAction)gridMenuTarget: sender
{
	NSString *item;
	int grid;

	item = [sender titleOfSelectedItem];
	sscanf([item UTF8String], "grid %d", &grid);

	if (grid == gridsize)
		return;

	gridsize = grid;
	[self setNeedsDisplay:YES];
}

/*
===============================================================================

						FIRST RESPONDER METHODS

===============================================================================
*/

- (IBAction) cut:(id)sender
{
	[editworld_i cut:sender];
}

- (IBAction) copy:(id)sender
{
	[editworld_i copy:sender];
}

- (IBAction) paste:(id)sender
{
	[editworld_i paste:sender];
}

- (IBAction) delete:(id)sender
{
	[editworld_i delete:sender];
}

/*
===============================================================================

							RETURN INFO

===============================================================================
*/

- (BOOL)acceptsFirstMouse
{
	return YES;
}

@synthesize currentScale=scale;


/*
================
=
= getCurrentOrigin
=
= Returns the global map coordinates (unscaled) of the lower left corner
=
================
*/

- (NSPoint) getCurrentOrigin
{
	NSRect	global;

	global = [[self superview] bounds];

	return [self convertPoint: global.origin fromView: [self superview]];
}

- (IBAction)printInfo: sender
{
	NSPoint	wrld;

	wrld = [self getCurrentOrigin];
	printf ("getCurrentOrigin: %f, %f\n",wrld.x,wrld.y);
}


/*
====================
=
= displayDirty:
=
= Adjust for the scale and size of control points and line tics
=
====================
*/

- (void)displayDirty: (NSRect)dirty
{
	NSRect	rect;
	CGFloat	adjust;
	
	adjust = CPOINTDRAW*scale;
	if (adjust <= LINENORMALLENGTH)
		adjust = LINENORMALLENGTH+1;
		
	rect.origin.x = dirty.origin.x - adjust;
	rect.origin.y = dirty.origin.y - adjust;
	rect.size.width = dirty.size.width + adjust*2;
	rect.size.height = dirty.size.height + adjust*2;

	rect = NSIntegralRect(rect);

	[self setNeedsDisplayInRect:rect];
}


/*
===============================================================================

						UTILITY METHODS

===============================================================================
*/

/*
=======================
=
= getPointFrom:
=
= Returns the global (unscaled) world coordinates of an event location
=
=======================
*/

- (NSPoint) getGridPointFrom: (NSEvent const *)event
{
// convert to view coordinates
	NSPoint point;

	point = [event locationInWindow];
	point = [self convertPoint: point fromView: nil];

// adjust for grid
	point.x = (int)(((point.x)/gridsize)+0.5*(point.x<0?-1:1));
	point.y = (int)(((point.y)/gridsize)+0.5*(point.y<0?-1:1));
	point.x *= gridsize;
	point.y *= gridsize;
//	printf("X:%f\tY:%f\tgridsize:%d\n",point->x,point->y,gridsize);
	return point;
}

- (NSPoint) getPointFrom: (NSEvent const *)event
{
// convert to view coordinates
	NSPoint point;

	point = [event locationInWindow];
	return [self convertPoint:point fromView: nil];
}

/*
=================
=
= adjustFrameForOrigin:scale:
=
= Increases or decreases the frame size to accomodate a new origin and/or scale
= Org is in global map coordinates (unscaled)
= Does not redrawing, change the origin position, or scale
= Call this every time the window is scrolled, zoomed, resized, or the map bounds changes
=
==================
*/

- (void)adjustFrameForOrigin: (NSPoint)org
{
	[self adjustFrameForOrigin: org scale:scale];
}

- (void)adjustFrameForOrigin: (NSPoint)org scale: (CGFloat)scl
{
	NSRect map;
	NSRect newbounds;
	NSRect viewbounds;
	
// the frame rect of the MapView is the union of the map rect and the visible rect
// if this is different from the current frame, resize it
	if (scl != scale)
	{
//printf ("changed scale\n");
		[self setBoundsSize:NSMakeSize([self frame].size.width/scl, [self frame].size.height/scl)];
		scale = scl;
	}
	
	
//
// get the rects that is displayed in the superview
//
	newbounds = [[self superview] visibleRect];
	newbounds = [self convertRect: newbounds fromView: [self superview]];
	newbounds.origin = org;

	map = [editworld_i getBounds];

	newbounds = NSUnionRect(map, newbounds);

	viewbounds = [self bounds];

	if (newbounds.size.width != viewbounds.size.width ||
	    newbounds.size.height != viewbounds.size.height)
	{
//printf ("changed size\n");
		[self setFrameSize:NSMakeSize(newbounds.size.width*scale, newbounds.size.height*scale)];
	}

	if (newbounds.origin.x != viewbounds.origin.x ||
	    newbounds.origin.y != viewbounds.origin.y)
	{
//printf ("changed origin\n");
		[super setBoundsOrigin:newbounds.origin];
	}
}


/*
=======================
=
= setOrigin: scale:
=
= Scrolls and/or scales the view to a new position and displays
= Org is in global map coordinates (unscaled)
= Do not call before the view is installed in a scroll view!
=
=======================
*/

- (void)setOrigin: (NSPoint) org
{
	[self setOrigin: org scale: scale];
}

- (void)setOrigin: (NSPoint) org scale: (CGFloat)scl
{
	[self adjustFrameForOrigin: org scale:scl];
	[self scrollPoint: org];
}

/*
====================
=
= zoomFrom:(NSPoint)origin scale:(float)newscale
=
= The origin is in screen pixels from the lower left corner of the clip view
=
====================
*/

- (void)zoomFrom:(NSPoint)origin toScale:(CGFloat)newscale
{
	NSPoint		neworg, orgnow;
	
	[[self window] disableFlushWindow];		// don't redraw twice (scaling and translating)
//
// find where the point is now
//
	neworg = [self convertPoint: origin toView: nil];

//
// change scale
//
	[self setBoundsSize:NSMakeSize([self frame].size.width/newscale, [self frame].size.height/newscale)];
	scale = newscale;

//
// convert the point back
//
	neworg = [self convertPoint: neworg fromView: NULL];
	orgnow = [self getCurrentOrigin];
	orgnow.x += origin.x - neworg.x;
	orgnow.y += origin.y - neworg.y;
	[self setOrigin: orgnow];

//
// redraw
// 
	[[self window] enableFlushWindow];
	//[[[self superview] superview] setNeedsDisplay:YES];  // redraw everything just once
}



@end

