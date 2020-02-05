// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "MapView.h"
#import "MapWindow.h"
#import "PreferencePanel.h"

#ifndef REDOOMED // Original (Disable for ReDoomEd)
#   import "Timing.h"
#endif

#import "ToolPanel.h"
#import "SettingsPanel.h"
#import "Coordinator.h"
#import "pathops.h"
#include <ctype.h>

// some arrays are shared by all mapview for temporary drawing data

BOOL	linecross[9][9];

#define MAXPOINTS	200

@implementation MapView

#ifdef REDOOMED
// Cocoa version
+ (void) initialize
#else // Original
+ initialize
#endif
{
	int	x1,y1,x2,y2;
	
	for (x1=0 ; x1<3 ; x1++)
		for (y1=0 ; y1<3 ; y1++)
			for (x2=0 ; x2<3 ; x2++)
				for (y2=0 ; y2<3 ; y2++)
				{
					if  ( ( (x1<=1 && x2>=1) || (x1>=1 && x2<=1) ) 
					&& ( (y1<=1 && y2>=1) || (y1>=1 && y2<=1) ) )
						linecross[y1*3+x1][y2*3+x2] = YES;
					else
						linecross[y1*3+x1][y2*3+x2] = NO;
				}
		
#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}


/*
==================
=
= initFromEditWorld
=
==================
*/

-initFromEditWorld
{
	NXRect	aRect;

#ifdef REDOOMED
	// moved call to super's initializer here, before member setup (gridsize, scale)
	NXSetRect (&aRect, 0,0, 100,100);	// call -setOrigin after installing in clip view
	self = [super initWithFrame: aRect];	// to set the proper rectangle

	if (!self)
		return nil;
#endif

	 if (![editworld_i loaded])
	 {
		NXRunAlertPanel ("Error","MapView inited with NULL world",NULL,NULL,NULL);

#ifdef REDOOMED
		// prevent memory leaks
		 [self release];
#endif

		return NULL;
	}
	
	gridsize = 8;		// these are changed by the pop up menus
	scale = 1;
	
#ifndef REDOOMED // Original (Disable for ReDoomEd - moved init call, removed setOpaque: (see below))
	NXSetRect (&aRect, 0,0, 100,100);	// call -setOrigin after installing in clip view
	[super initFrame: &aRect];			// to set the proper rectangle
	[self setOpaque: YES];
#endif
		
	return self;
}

#ifdef REDOOMED
// removed call to -[self setOpaque: YES] from init method above; View opacity in Cocoa is
// controlled by overriding -[NSView isOpaque] method:
- (BOOL) isOpaque
{
	return YES;
}
#endif


#define TESTOPS	1000

- testSpeed: sender
{
#ifndef REDOOMED // Original (Disable for ReDoomEd - writes to hardcoded filepath)
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
		[self setNeedsDisplay:YES];
		[t4 leave];
	}
	[t4 summary: stream];
printf ("No flush\n");	
	[t4 reset];
	[window disableFlushWindow];
	for (i=0 ; i<10 ; i++)
	{
		[t4 enter: WALLTIME];
		[self setNeedsDisplay:YES];
		[t4 leave];
	}
	[window reenableFlushWindow];
	[t4 summary: stream];
	
	NXSaveToFile (stream, "/aardwolf/Users/johnc/timing.txt");
	NXClose (stream);
printf ("Done\n");	
#endif // REDOOMED
	
	return self;
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

- worldBoundsChanged
{
	return self;
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
	char	const	*item;
	float			nscale;
	NXRect		visrect;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'superview' as an instance var, fake it using a local
	NSView *superview = [self superview];
#endif
	
#ifdef REDOOMED
	item = RDE_CStringFromNSString([[sender selectedCell] title]);
#else // Original
	item = [[sender selectedCell] title];
#endif

	sscanf (item,"%f",&nscale);
	nscale /= 100;
	
	if (nscale == scale)
		return;
		
// try to keep the center of the view constant
	visrect = [superview visibleRect];
	visrect = [self convertRect: visrect fromView: [self superview]];
	visrect.origin.x += visrect.size.width/2;
	visrect.origin.y += visrect.size.height/2;
	
	[self zoomFrom: &visrect.origin toScale: nscale];
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
	char	const	*item;
	int			grid;
	
#ifdef REDOOMED
	item = RDE_CStringFromNSString([[sender selectedCell] title]);
#else // Original
	item = [[sender selectedCell] title];
#endif

	sscanf (item,"grid %d",&grid);

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

- (void)cut: sender
{
	[editworld_i cut:sender];
}

- (void)copy: sender
{
	[editworld_i copy:sender];
}

- (void)paste: sender
{
	[editworld_i paste:sender];
}

- (void)delete: sender
{
	[editworld_i delete:sender];
}

/*
===============================================================================

							RETURN INFO

===============================================================================
*/

#ifdef REDOOMED
// Cocoa version
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
#else // Original
- (BOOL)acceptsFirstMouse
#endif
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

- getCurrentOrigin: (NXPoint *)worldorigin
{
	NXRect	global;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'superview' as an instance var, fake it using a local
	NSView *superview = [self superview];
#endif
	
	global = superview.bounds;
	[self convertPointFromSuperview: &global.origin];
	*worldorigin = global.origin;
	
	return self;
}

- (IBAction)printInfo: sender
{
	NXPoint	wrld;
	
	[self getCurrentOrigin: &wrld];
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

- displayDirty: (NXRect const *)dirty
{
	NXRect	rect;
	float		adjust;
	
#ifdef REDOOMED
	// Bugfix: control point sizes are calculated using CPOINTDRAW/scale, not CPOINTDRAW*scale
	// (fixes the drawing artifacts left behind when dragging selected points on scales < 1,
	// due to an incorrectly-small adjust value used to expand the dirty rect)
	adjust = CPOINTDRAW/scale;
#else // Original
	adjust = CPOINTDRAW*scale;
#endif

	if (adjust <= LINENORMALLENGTH)
		adjust = LINENORMALLENGTH+1;
		
	rect.origin.x = dirty->origin.x - adjust;
	rect.origin.y = dirty->origin.y - adjust;
	rect.size.width = dirty->size.width + adjust*2;
	rect.size.height = dirty->size.height + adjust*2;
	
	NXIntegralRect (&rect);
	
	return [self display: &rect : 1];
}


/*
===============================================================================

						UTILITY METHODS

===============================================================================
*/

/*
=======================
=
= getPoint: from:
=
= Returns the global (unscaled) world coordinates of an event location
=
=======================
*/

- 	getGridPoint:	(NXPoint *)point 
	from: 	(NXEvent const *)event
{
// convert to view coordinates

#ifdef REDOOMED
	*point = [event locationInWindow];
	*point = [self convertPoint:*point  fromView:nil];
#else // Original
	*point = event->location;
	[self convertPoint:point  fromView:NULL];
#endif

// adjust for grid
	point->x = (int)(((point->x)/gridsize)+0.5*(point->x<0?-1:1));
	point->y = (int)(((point->y)/gridsize)+0.5*(point->y<0?-1:1));
	point->x *= gridsize;
	point->y *= gridsize;
//	printf("X:%f\tY:%f\tgridsize:%d\n",point->x,point->y,gridsize);
	return self;
}

- 	getPoint:	(NXPoint *)point 
	from: 	(NXEvent const *)event
{
// convert to view coordinates

#ifdef REDOOMED
	*point = [event locationInWindow];
	*point = [self convertPoint:*point  fromView:nil];
#else // Original
	*point = event->location;
	[self convertPoint:point  fromView:NULL];
#endif

	return self;
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

- adjustFrameForOrigin: (NXPoint const *)org
{
	return [self adjustFrameForOrigin: org scale:scale];
}

- adjustFrameForOrigin: (NXPoint const *)org scale: (float)scl
{
	NXRect	map;
	NXRect	newbounds;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'frame', 'bounds', or 'superview' as instance
	// vars, fake them using locals
	NSRect frame = [self frame];
	NSRect bounds = [self bounds];
	NSView *superview = [self superview];
#endif
	
// the frame rect of the MapView is the union of the map rect and the visible rect
// if this is different from the current frame, resize it
	if (scl != scale)
	{
//printf ("changed scale\n");
		[self setDrawSize: frame.size.width/scl : frame.size.height/scl];
		scale = scl;

#ifdef REDOOMED
		// update the fake 'bounds' ivar with the view's new bounds (changed by setDrawSize::)
		bounds = [self bounds];
#endif
	}
	
	
//
// get the rects that is displayed in the superview
//
	newbounds = superview.visibleRect;
	[self convertRectFromSuperview: &newbounds];
	newbounds.origin = *org;
	
	[editworld_i getBounds: &map];
	
	NXUnionRect (&map, &newbounds);
	
	if (
	newbounds.size.width != bounds.size.width ||
	newbounds.size.height != bounds.size.height 
	)
	{
//printf ("changed size\n");
		[self sizeTo: newbounds.size.width*scale : newbounds.size.height*scale];
	}

	if (
	newbounds.origin.x != bounds.origin.x ||
	newbounds.origin.y != bounds.origin.y
	)
	{
//printf ("changed origin\n");
		[self setDrawOrigin: newbounds.origin.x : newbounds.origin.y];
	}
		
	return self;
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

- setOrigin: (NXPoint const *)org
{
	return [self setOrigin: org scale: scale];
}

- setOrigin: (NXPoint const *)org scale: (float)scl
{
	[self adjustFrameForOrigin: org scale:scl];

#ifdef REDOOMED
	// Cocoa's scrollPoint: takes a value, not a pointer
	[self scrollPoint: *org];
#else // Original
	[self scrollPoint: org];
#endif

	return self;
}

/*
====================
=
= zoomFrom:(NXPoint *)origin scale:(float)newscale
=
= The origin is in screen pixels from the lower left corner of the clip view
=
====================
*/

- zoomFrom:(NXPoint *)origin toScale:(float)newscale
{
	NXPoint		neworg, orgnow;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'window' or 'frame' as instance vars,
	// fake them using locals
	NSWindow *window = [self window];
	NSRect frame = [self frame];
#endif
	
	[window disableDisplay];		// don't redraw twice (scaling and translating)
//
// find where the point is now
//
	neworg = *origin;

#ifdef REDOOMED
	neworg = [self convertPoint: neworg toView: nil];
#else // Original
	[self convertPoint: &neworg toView: NULL];
#endif
	
//
// change scale
//		
	[self setDrawSize: frame.size.width/newscale : frame.size.height/newscale];
	scale = newscale;

//
// convert the point back
//
#ifdef REDOOMED
	neworg = [self convertPoint: neworg fromView: nil];
#else // Original
	[self convertPoint: &neworg fromView: NULL];
#endif

	[self getCurrentOrigin: &orgnow];
	orgnow.x += origin->x - neworg.x;
	orgnow.y += origin->y - neworg.y;
	[self setOrigin: &orgnow];
	
//
// redraw
// 
	[window reenableDisplay];

#ifdef REDOOMED
	[self displayIfNeeded]; // avoid unnecessary redrawing
#else // Original
	[[superview superview] display];	// redraw everything just once
#endif
	
	return self;
}



@end

