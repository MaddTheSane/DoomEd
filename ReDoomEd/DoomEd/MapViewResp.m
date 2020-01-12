// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "MapViewResp.h"
#import "MapView.h"
#import "MapWindow.h"
#import "PreferencePanel.h"

#ifndef REDOOMED // Original (Disable for ReDoomEd)
#   import "Timing.h"
#endif

#import "ToolPanel.h"
#import <ctype.h>
#import "EditWorld.h"
#import "idfunctions.h"
#import "pathops.h"
#import "LinePanel.h"
#import "SectorEditor.h"
#import "SettingsPanel.h"
#import "BlockWorld.h"
#import "ThingPanel.h"

#define FRAMEWIDTH		4
#define SELECTIONGRAY	0.5

@implementation MapView (MapViewResp)

/*
===============================================================================

						WORLD UTILITY METHODS

===============================================================================
*/

/*
===================
=
= addLineFrom: to:
=
= Adds a new line of the type specified in the various panels and selects it and its points
= Called by lineDrag and polyDrag
=
====================
*/

- addLineFrom: (NXPoint *)fixedpoint  to: (NXPoint *)dragpoint
{
	worldline_t	newline;
	int			line;

	[linepanel_i baseLine: &newline];

	line = [editworld_i newLine: &newline from: fixedpoint to: dragpoint];
	
	[editworld_i selectLine: line];
	[editworld_i selectPoint: lines[line].p1];
	[editworld_i selectPoint: lines[line].p2];
	
	return self;
}

/*
===============================================================================

						RESPONDER METHODS

===============================================================================
*/

/*
===============
=
= slideView:
=
= Scroll the view in response to dragging
=
===============
*/

- slideView:(NXEvent *)event
{
	int 		oldMask;
	NXPoint	oldpt, pt, origin;
	float		dx, dy;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'window' as an instance var, fake it using a local
	NSWindow *window = [self window];
	unsigned int eventType;
#endif
			
#ifdef REDOOMED
	oldpt = [event locationInWindow];
	oldpt = [self convertPoint: oldpt fromView: nil];
#else // Original
	oldpt = event->location;
	[self convertPoint: &oldpt fromView: NULL];
#endif
	
	oldMask = [window addToEventMask:NX_MOUSEDRAGGEDMASK | NX_RMOUSEDRAGGEDMASK];
	
	do 
	{
		event = [NXApp getNextEvent: NX_MOUSEUPMASK | NX_RMOUSEUPMASK | NX_MOUSEDRAGGEDMASK | NX_RMOUSEDRAGGEDMASK];

#ifdef REDOOMED
		eventType = [event type];
		if (eventType == NX_MOUSEUP || eventType == NX_RMOUSEUP)
			break;

		pt = [event locationInWindow];
		pt = [self convertPoint: pt fromView: nil];
#else // Original
		if (event->type == NX_MOUSEUP || event->type == NX_RMOUSEUP)
			break;
			
		pt = event->location;
		[self convertPoint: &pt fromView: NULL];
#endif

		dx = oldpt.x - pt.x;
		dy= oldpt.y - pt.y;
		
		if (dx != 0 || dy != 0)
		{
			[self getCurrentOrigin: &origin];
			origin.x += dx;
			origin.y += dy;
			[window disableDisplay];
			[self setOrigin: &origin];
			[window reenableDisplay];

#ifdef REDOOMED
			[self displayIfNeeded]; // avoid unnecessary redrawing
			oldpt = [event locationInWindow];
			oldpt = [self convertPoint: oldpt fromView: nil];
			// removed the call to setDirtyMap: - scrolling the view shouldn't affect the map's
			// edited state
#else // Original
			[[superview superview] display];	// redraw everything just once
			oldpt = event->location;
			[self convertPoint: &oldpt fromView: NULL];
			[doomproject_i	setDirtyMap:TRUE];
#endif
		}
	} while (1);
	
	[window setEventMask:oldMask];
	
	return self;
}


/*
================
=
= zoomIn:
=
================
*/

- zoomIn:(NXEvent *)event
{
	char	const	*item;
	float			nscale;
	id			itemlist;
	int			selected, numrows, numcollumns;
	NXPoint		origin;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'window' as an instance var, fake it using a local
	MapWindow *window = (MapWindow *) [self window];
#endif
	
	itemlist = [[window scalemenu] itemList];
	[itemlist getNumRows: &numrows numCols:&numcollumns];
	
	selected = [itemlist selectedRow] + 1;
	if (selected >= numrows)
		return NULL;
		
	[itemlist selectCellAt: selected : 0];
	[[window scalebutton] setTitle: [[itemlist selectedCell] title]];

// parse the scale from the title
#ifdef REDOOMED
	item = RDE_CStringFromNSString([[itemlist selectedCell] title]);
#else // Original
	item = [[itemlist selectedCell] title];
#endif

	sscanf (item,"%f",&nscale);
	nscale /= 100;
	
// keep the cursor point of the view constant

#ifdef REDOOMED
	origin = [event locationInWindow];
	origin = [self convertPoint:origin  fromView:nil];
#else // Original
	origin = event->location;
	[self convertPoint:&origin  fromView:NULL];
#endif

//printf ("origin: %f,%f\n",origin.x,origin.y);
	[self zoomFrom: &origin toScale: nscale];
	
//
// allow a drag while the mouse is still down
//
	[self slideView: event];
	
	return self;
}

/*
================
=
= zoomOut:
=
================
*/

- zoomOut:(NXEvent *)event
{
	char	const	*item;
	float			nscale;
	id			itemlist;
	int			selected;
	NXPoint		origin;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'window' as an instance var, fake it using a local
	MapWindow *window = (MapWindow *) [self window];
#endif

	itemlist = [[window scalemenu] itemList];
	selected = [itemlist selectedRow] - 1;
	
	if (selected < 0)
		return NULL;
		
	[itemlist selectCellAt: selected : 0];
	[[window scalebutton] setTitle: [[itemlist selectedCell] title]];
	
// parse the scale from the title
#ifdef REDOOMED
	item = RDE_CStringFromNSString([[itemlist selectedCell] title]);
#else // Original
	item = [[itemlist selectedCell] title];
#endif

	sscanf (item,"%f",&nscale);
	nscale /= 100;
	
// keep the cursor point of the view constant

#ifdef REDOOMED
	origin = [event locationInWindow];
	origin = [self convertPoint:origin  fromView:nil];
#else // Original
	origin = event->location;
	[self convertPoint:&origin  fromView:NULL];
#endif

//printf ("origin: %f,%f\n",origin.x,origin.y);
	
	[self zoomFrom: &origin toScale: nscale];
	
//
// allow a drag while the mouse is still down
//
	[self slideView: event];

	return self;
}


//=============================================================================


/*
================
=
= lineDrag:
=
= Rubber band a new line from the starting position
=
================
*/

- lineDrag:(NXEvent *)event
{
	int 		oldMask;
	NXPoint	fixedpoint, dragpoint;	// endpoints of the line
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'window' as an instance var, fake it using a local
	NSWindow *window = [self window];
#endif
		
	oldMask = [window addToEventMask:NX_LMOUSEDRAGGEDMASK];
	
	[self lockFocus];
	PSsetinstance (YES);
	PSsetlinewidth (0.15);
	NXSetColor ([prefpanel_i colorFor: [settingspanel_i segmentType]]);

	[self getGridPoint: &fixedpoint from: event];		// handle grid and sutch
	
	do 
	{
		[self getGridPoint: &dragpoint  from: event];  // handle grid and sutch
		
		PSnewinstance ();
		
		PSmoveto (fixedpoint.x, fixedpoint.y);
		PSlineto (dragpoint.x, dragpoint.y);
		PSstroke ();
		NXPing ();
		
		event = [NXApp getNextEvent: NX_LMOUSEUPMASK | NX_LMOUSEDRAGGEDMASK];
#ifdef REDOOMED
	} while ([event type] != NX_LMOUSEUP);
#else // Original
	} while (event->type != NX_LMOUSEUP);
#endif
	
//
// add to the world
//
	[window setEventMask:oldMask];

	PSnewinstance ();
	PSsetinstance (NO);
	[self unlockFocus];
	
	if ( dragpoint.x == fixedpoint.x && dragpoint.y == fixedpoint.y )
		return NULL;			// outside world or same point
	
	[editworld_i deselectAll];
	[self addLineFrom: &fixedpoint  to: &dragpoint];
	[editworld_i updateWindows];	
	[doomproject_i	setDirtyMap:TRUE];	

	return self;
}

//=============================================================================

/*
================
=
= polyDrag:
=
================
*/

- polyDrag:(NXEvent *)event
{
	int 		oldMask;
	NXPoint	fixedpoint, dragpoint;	// endpoints of the line
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'window' as an instance var, fake it using a local
	NSWindow *window = [self window];
#endif

//
// set up
//	
	[self lockFocus];
	PSsetlinewidth (0.15);
	NXSetColor ([prefpanel_i colorFor: [settingspanel_i segmentType]]);

//
// wait for a mouse up to specify first point
//
	do
	{
		event = [NXApp getNextEvent: NX_LMOUSEUPMASK];
#ifdef REDOOMED
	} while ([event type] != NX_LMOUSEUP);
#else // Original
	} while (event->type != NX_LMOUSEUP);
#endif

//
// drag lines until a click on same point
//
	do
	{
		[self getGridPoint: &fixedpoint from: event];	// handle grid and sutch
		oldMask = [window addToEventMask:NX_MOUSEMOVEDMASK];
		PSsetinstance (YES);
	
		do 
		{
			event = [NXApp getNextEvent: NX_LMOUSEDOWNMASK | NX_LMOUSEUPMASK | NX_MOUSEMOVEDMASK | NX_LMOUSEDRAGGEDMASK];
			[self getGridPoint: &dragpoint  from: event];  // handle grid and sutch

#ifdef REDOOMED
			if ([event type] == NX_LMOUSEUP)
#else // Original
			if (event->type == NX_LMOUSEUP)
#endif
				break;
				
			PSnewinstance ();
			PSmoveto (fixedpoint.x, fixedpoint.y);
			PSlineto (dragpoint.x, dragpoint.y);
			PSstroke ();
			NXPing ();			
		} while (1);
	
//
// add to the world
//
		[window setEventMask:oldMask];
	
		PSnewinstance ();
		PSsetinstance (NO);

		if ( dragpoint.x == fixedpoint.x && dragpoint.y == fixedpoint.y )
			break;			// outside world or same point

		[self addLineFrom: &fixedpoint  to: &dragpoint];
		[editworld_i updateWindows];		
		[doomproject_i	setDirtyMap:TRUE];
	} while (1);
	
	[self unlockFocus];
		
	return self;
}

//=============================================================================

/*
================
=
= dragSelectedPoints:
=
 the fixedrect is the rect enclosing any points connected by lines to the selected points
 
 the dragrect is the rect that encloses all the selected points, with the
 initial click being the origin
 
 currentdragrect is dragrect+cursor
 
 the updaterect is the (currentdragrect union olddragrect union fixedrect)
 
 if only one point is selected, it is snapped to grid
 
================
*/

- dragSelectedPoints: (NXEvent *)event
{
	int 		oldMask;
	int		l;
	int			linecount, *linelist, *linelist_p;
	worldline_t	*line_p;
	BOOL		side1, side2;
	NXPoint		cursor, moved,totalmoved;
	NXRect		fixedrect;
	NXRect		dragrect;
	NXRect		currentdragrect, olddragrect;
	NXRect		updaterect;
	int			p, lastp;
	worldpoint_t	*point_p, newpoint;
	int			pointcount;
	float		offset;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'window' as an instance var, fake it using a local
	NSWindow    *window = [self window];
#endif
		
	[self getGridPoint: &cursor  from: event];  // handle grid and sutch
	
// set up negative rects
	fixedrect.origin.x = MAXFLOAT/4;
	fixedrect.origin.y = MAXFLOAT/4;
	fixedrect.size.width = -MAXFLOAT/2;
	fixedrect.size.height = -MAXFLOAT/2;
	dragrect = fixedrect;
	
// if only one endpoint of a line is selected, the other end will contribute to the fixedrect
// Any lines that touch the points need to have their normals updated during dragging

	linelist = linelist_p = alloca(numlines*sizeof(*linelist));
	
	for (l=0, line_p = lines ; l<numlines ; l++, line_p++)
	{
		if (line_p->selected == -1)
			continue;
			
		side1 = points[line_p->p1].selected == 1;
		side2 = points[line_p->p2].selected == 1;
		
		if (side1 || side2)
			*linelist_p++ = l;
		
		if (side1 && !side2)
			IDEnclosePoint (&fixedrect, &points[line_p->p2].pt); // p2 is fixed
		else if (side2 && !side1)
			IDEnclosePoint (&fixedrect, &points[line_p->p1].pt); // p1 is fixed
	}
	linecount = linelist_p - linelist;
	
//
// the dragrect encloses all selected points
//
#ifdef REDOOMED
	// Bugfix: removed scale as a factor for calculating thing-size offset (affects
	// dragrect & updaterect), because things' draw size is not dependent on scale -
	// this fixes draw artifacts that could appear when dragging things on scales > 1,
	// because the redraw bounds (updaterect) was too small
	offset = THINGDRAWSIZE/2 + 2;
#else // Original
	offset = THINGDRAWSIZE/2/scale + 2;
#endif
	
	pointcount = 0;
	for (p=0 , point_p = points ; p<numpoints ; p++, point_p++)
	{
		if (point_p->selected == 1)
		{
			pointcount++;
			lastp = p;
			IDEnclosePoint (&dragrect, &point_p->pt);
		}
	}
	
	for (p=0; p<numthings;p++)
		if (things[p].selected == 1)
		{
			NXPoint	pt;
			
			pt = things[p].origin;
			pt.x -= offset;
			pt.y -= offset;
			IDEnclosePoint(&dragrect,&pt);
			pt.x = things[p].origin.x + offset;
			pt.y = things[p].origin.y + offset;
			IDEnclosePoint(&dragrect,&pt);
		}

	olddragrect = dragrect;		// absolute coordinates
	
#ifdef REDOOMED
	// Bugfix: when dragging a single control point, make sure the dragrect encloses the
	// initial cursor point; at scales < 1, a cursor point that's considered a hit on a
	// control point may be far enough away that the dragrect (calculated using the control
	// point) doesn't touch the cursor point - this can cause the dragged control point
	// (set to the current cursor point each time through the single-point logic in the
	// loop below) to be drawn outside the bounds of the updaterect (the dirty rect used to
	// redraw the view, which is calculated by offsetting the dragrect from the initial
	// cursor point to the current cursor point), so previously-drawn dragged points may
	// not be redrawn (erased) when the control point's dragged to a new location (leaving
	// draw artifacts)
	if (pointcount == 1)
	{
		dragrect.origin = cursor;
	}
#endif

	dragrect.origin.x -= cursor.x;	// relative to cursor
	dragrect.origin.y -= cursor.y;
	
//
// modal dragging loop
//
	oldMask = [window addToEventMask:NX_LMOUSEDRAGGEDMASK];
	moved = totalmoved = cursor;
	
	do 
	{		
		event = [NXApp getNextEvent: NX_LMOUSEUPMASK | NX_LMOUSEDRAGGEDMASK];

#ifdef REDOOMED
		if ( [event type] == NX_LMOUSEUP)
#else // Original
		if ( event->type == NX_LMOUSEUP)
#endif
			break;
		//
		// calculate new rectangle
		//
		[self getGridPoint: &cursor  from: event];  // handle grid and such

		//
		// move all selected points
		//
		if (pointcount == 1)
		{
			if (points[lastp].pt.x == cursor.x && points[lastp].pt.y == cursor.y)
				continue;
			points[lastp].pt = cursor;
		}
		else
		{
			if (cursor.x == moved.x && cursor.y == moved.y)
				continue;
				
			moved.x = cursor.x - moved.x;
			moved.y = cursor.y - moved.y;	
		
			for (p=0 , point_p = points ; p<numpoints ; p++, point_p++)
			{
				if (point_p->selected == 1)
				{
					point_p->pt.x += moved.x;
					point_p->pt.y += moved.y;
				}
			}
			
			for (p=0; p < numthings;p++)
				if (things[p].selected == 1)
				{
					things[p].origin.x += moved.x;
					things[p].origin.y += moved.y;
				}

			if (moved.x || moved.y)
				[doomproject_i	setDirtyMap:TRUE];
				
			moved = cursor;
		}
		
		//
		// update line normals
		//
		for (l = 0 ; l < linecount ; l++)
			[editworld_i updateLineNormal: linelist[l]];
		
		//
		// redraw new frame
		//
		currentdragrect = dragrect;
		currentdragrect.origin.x += cursor.x;
		currentdragrect.origin.y += cursor.y;
		updaterect = currentdragrect;
		NXUnionRect (&olddragrect, &updaterect);
		NXUnionRect (&fixedrect, &updaterect);
		olddragrect = currentdragrect;
		[self displayDirty: &updaterect];
		
	} while (1);

	[window setEventMask:oldMask];

	//
	// tell the world about the changes
	// the points have to be set back to their original positions before sending
	// the new point to the server so the dirty rect will contain everything touched
	// by the old and new positions
	//
	totalmoved.x = cursor.x - totalmoved.x;
	totalmoved.y = cursor.y - totalmoved.y;	
	
	for (p=0 ; p<numpoints ; p++)
		if (points[p].selected == 1)
		{
			newpoint = points[p];
			points[p].pt.x -= totalmoved.x;
			points[p].pt.y -= totalmoved.y;
			[editworld_i changePoint: p to: &newpoint];
			if (totalmoved.x || totalmoved.y)
				[doomproject_i	setDirtyMap:TRUE];
		}

	return self;
}


//=============================================================================

/*
================
=
= dragSelectionBox:
=
================
*/

- dragSelectionBox: (NXEvent *)event
{
	int 		oldMask;
	NXRect	newframe;
	NXPoint	dragcorner, fixedcorner, *p1, *p2;
	int		i,p;
	worldpoint_t	*point_p;
	worldthing_t	*thing_p;
	box_t		box1, box2;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'window' as an instance var, fake it using a local
	NSWindow *window = [self window];
#endif
	
//
// peg down the first corner
//
#ifdef REDOOMED
	fixedcorner = [event locationInWindow];
	fixedcorner = [self convertPoint:fixedcorner  fromView:nil];
#else // Original
	fixedcorner = event->location;
	[self convertPoint:&fixedcorner  fromView:NULL];
#endif
		
//
// move drag
//	
	oldMask = [window addToEventMask:NX_LMOUSEDRAGGEDMASK];
	
	[self lockFocus];
	PSsetinstance (YES);
	PSsetgray (SELECTIONGRAY);
	
	do 
	{
		//
		// calculate new rectangle
		//
#ifdef REDOOMED
		dragcorner = [event locationInWindow];
		dragcorner = [self convertPoint:dragcorner  fromView:nil];
#else // Original
		dragcorner = event->location;
		[self convertPoint:&dragcorner  fromView:NULL];
#endif

		IDRectFromPoints (&newframe, &fixedcorner, &dragcorner);
				
		//
		// redraw new frame
		//
		PSnewinstance ();
		NXFrameRectWithWidth(&newframe, FRAMEWIDTH);
		NXPing ();
		
		event = [NXApp getNextEvent: NX_LMOUSEUPMASK | NX_LMOUSEDRAGGEDMASK];
		
#ifdef REDOOMED
	} while ([event type] != NX_LMOUSEUP);
#else // Original
	} while (event->type != NX_LMOUSEUP);
#endif

	[window setEventMask:oldMask];
	PSnewinstance ();
	PSsetinstance (NO);
	[self unlockFocus];
	
//
// grab points inside newframe
//
	for (p=0 , point_p = points ; p<numpoints ; p++, point_p++)
	{
		if (point_p->selected == -1)
			continue;
		if ( NXPointInRect (&point_p->pt, &newframe) )
			[editworld_i selectPoint: p];
	}

//
// grab lines inside newframe
//
	[self lockFocus];
	PSsetlinewidth (1);
	BoxFromRect (&box1, &newframe);	
	for (i=0 ; i<numlines ; i++)
	{
		if (lines[i].selected == -1)
			continue;				// deleted line
		
		p1 = &points[lines[i].p1].pt;
		p2 = &points[lines[i].p2].pt;
		
		BoxFromPoints (&box2, p1, p2);	

		if ( box1.right < box2.left || box1.left > box2.right
		|| box1.top < box2. bottom || box1.bottom > box2.top)
			continue;

		if (LineInRect (p1, p2, &newframe))
		{
		// hit a line
			[editworld_i selectLine: i];
			// select points at ends
			[editworld_i selectPoint: lines[i].p1];
			[editworld_i selectPoint: lines[i].p2];
		}
	}
		
	[self unlockFocus];

//
// grab things inside newframe
//
	for (p=0 , thing_p = things ; p<numthings ; p++, thing_p++)
	{
		if (thing_p->selected == -1)
			continue;
		if ( NXPointInRect (&thing_p->origin, &newframe) )
			[editworld_i selectThing: p];
	}

		
	return self;
}

//============================================================================

/*
================
=
= pointSelect:
=
================
*/

- pointSelect:(NXEvent *)event
{
	int			i;
	worldthing_t	*thing_p;
	worldpoint_t	const *point_p;
	float			left, right, top, bottom;
	NXPoint		*p1, *p2;
	NXPoint		clickpoint;
	int			instroke;
	
	[self getPoint: &clickpoint from: event];
	

//
// see if the click hit a point
//
	left = clickpoint.x - CPOINTSIZE/scale/2;
	right = clickpoint.x + CPOINTSIZE/scale/2;
	bottom = clickpoint.y  - CPOINTSIZE/scale/2;
	top = clickpoint.y+ CPOINTSIZE/scale/2;


	for (i=0, point_p = points; i<numpoints ; i++,point_p++)
	{
		if (point_p->selected == -1)
			continue;
		if (point_p->pt.x > left && point_p->pt.x < right 
		&& point_p->pt.y < top && point_p->pt.y > bottom)
			break;
	}
	
	if (i<numpoints)
	{	// the click was on a point
		if (point_p->selected)
		{
#ifdef REDOOMED
			if  ( [event modifierFlags] & NX_SHIFTMASK )
#else // Original
			if  ( event->flags & NX_SHIFTMASK )
#endif
			{	// shift click a selected point deselects it
				[editworld_i deselectPoint: i];
				return self;
			}
		}
		else
		{
// if not clicking on a selection and not shift clicking, deselect all selected points
#ifdef REDOOMED
			if ( !([event modifierFlags] & NX_SHIFTMASK) )
#else // Original
			if ( !(event->flags & NX_SHIFTMASK) )
#endif
				[editworld_i deselectAll];
			[editworld_i selectPoint: i];
		}
		[editworld_i updateWindows];
		[self dragSelectedPoints: event];	// drag all points around
		return self;
	}
	
//
// didn't hit a point, so check lines
//
	[self lockFocus];

#ifdef REDOOMED
	// Bugfix: line width for hit-testing should be CPOINTSIZE/scale, not CPOINTSIZE*scale
    // (see control point hit-testing above) - this fixes the issue where lines are hard to
    // click when scale < 1, due to an incorrectly-small line-width value used to check hits
	PSsetlinewidth (CPOINTSIZE/scale);
#else // Original
	PSsetlinewidth (CPOINTSIZE*scale);	// line width same as contrtol points
#endif

	for (i=0 ; i<numlines ; i++)
	{
		if (lines[i].selected == -1)
			continue;				// deleted line
			
		p1 = &points[lines[i].p1].pt;
		p2 = &points[lines[i].p2].pt;
		
		if ( (p1->x < left && p2->x < left)
		|| (p1->x > right && p2->x > left)
		|| (p1->y > top && p2->y > top)
		|| (p1->y < bottom && p2->y < bottom) )
			continue;
			
		PSnewpath ();
		PSmoveto (p1->x,p1->y);
		PSlineto (p2->x,p2->y);
		PSinstroke (clickpoint.x, clickpoint.y, &instroke);
		if (instroke)
		{
		// hit a line
			[self unlockFocus];
			// deselect any other points if shift not down
#ifdef REDOOMED
			if ( !([event modifierFlags] & NX_SHIFTMASK) && lines[i].selected != 1)
#else // Original
			if ( !(event->flags & NX_SHIFTMASK) && lines[i].selected != 1)
#endif
				[editworld_i deselectAll];
				
#ifdef REDOOMED
			if ([event modifierFlags] & NX_SHIFTMASK && lines[i].selected == 1)
#else // Original
			if (event->flags & NX_SHIFTMASK && lines[i].selected == 1)
#endif
			{
				[editworld_i deselectLine: i];
				return self;
			}
			
			[editworld_i selectLine: i];
			
			// select points at ends
			[editworld_i selectPoint: lines[i].p1];
			[editworld_i selectPoint: lines[i].p2];
			
			[editworld_i updateWindows];
			[self dragSelectedPoints: event];	// drag all points around
			return self;
		}
	}
		
	
	[self unlockFocus];
	
//
// see if the click hit a thing
//
	left = clickpoint.x - THINGDRAWSIZE/2;
	right = clickpoint.x + THINGDRAWSIZE/2;
	bottom = clickpoint.y  - THINGDRAWSIZE/2;
	top = clickpoint.y+ THINGDRAWSIZE/2;


	for (i=0, thing_p = things; i<numthings ; i++,thing_p++)
	{
		if (thing_p->selected == -1)
			continue;
		if (thing_p->origin.x > left && thing_p->origin.x < right 
		&& thing_p->origin.y < top && thing_p->origin.y > bottom)
			break;
	}
	
	if (i<numthings)
	{	// click was on a thing
		// if not clicking on a selection and
		// ...not shift clicking, deselect all selected points
		// deselect any other points if shift not down
#ifdef REDOOMED
		if ( !([event modifierFlags] & NX_SHIFTMASK) && things[i].selected != 1)
#else // Original
		if ( !(event->flags & NX_SHIFTMASK) && things[i].selected != 1)
#endif
			[editworld_i deselectAll];
		[editworld_i selectThing: i];
		[self dragSelectedPoints: event];	// drag all points around
		return self;
	}
	

//
// the click was not on a point, so rubber band a selection box
//
#ifdef REDOOMED
	if (! ([event modifierFlags] & NX_SHIFTMASK) )
#else // Original
	if (! (event->flags & NX_SHIFTMASK) )
#endif
	{
	// if not shift clicking, deselect all selected points
		[editworld_i deselectAll];
		[editworld_i updateWindows];
	}

	[self dragSelectionBox: event];
	
	return self;
}

//=============================================================================

/*
================
=
= placeThing:
=
================
*/

- placeThing: (NXEvent *)event
{
	worldthing_t	thing;
	
	[editworld_i deselectAll];
	
	[self getGridPoint: &thing.origin from: event];
	
	[thingpanel_i	getThing:&thing];
	thing.selected = 0;
	[editworld_i newThing: &thing];
	[doomproject_i	setDirtyMap:TRUE];
	
	return self;
}


//=============================================================================

/*
================
=
= fillSector:
=
================
*/

- fillSector: (NXEvent *)event
{
	NXPoint	pt;
	int		i, side;
	worldline_t	*line;
	sectordef_t	*fillends;

	fillends = [sectorEdit_i getSector];
	
	[self getPoint: &pt from: event];
	[blockworld_i floodFillSector: &pt];
	
	for (i=0 ; i<numlines ; i++)
	{
		line = &lines[i];
		if (line->selected <1 )
			continue;
		side = line->selected-1;
		line->side[side].ends = *fillends;
	}
	[doomproject_i	setDirtyMap:TRUE];
	
	return self;
}

//=============================================================================

/*
================
=
= getSector:
=
================
*/

- getSector: (NXEvent *)event
{
	NXPoint	pt;
	int		line, side;
	sectordef_t	*def;

	[self getPoint: &pt from: event];	
	line = LineByPoint (&pt, &side);
	
	def = &lines[line].side[side].ends;
	
	[sectorEdit_i	setSector: def];
	
	return self;
}


//============================================================================

- (int)scanForErrors
{
	int	i;
	for (i=0;i<numthings;i++)
		if (things[i].selected == 1)
			return 1;
	for (i=0;i<numlines;i++)
		if (lines[i].selected == 1)
			return 1;
	return 0;	
}

- launchAndSave:(NXEvent *)event
{
	NXPoint	pt;
	int	i,player1Type;
	worldthing_t	oldthing,newthing;
	
	player1Type = [prefpanel_i	getLaunchThingType];
	[self getPoint: &pt from: event];
	for (i=0;i < numthings; i++)
		if (things[i].type == player1Type)
		{
			newthing = oldthing = things[i];
			newthing.origin = pt;
			[editworld_i	changeThing:i		to:&newthing];
			[editworld_i	redrawWindows];
			[editworld_i	saveDoomEdMapBSP:NULL];
			[editworld_i	changeThing:i		to:&oldthing];
			[editworld_i	redrawWindows];
			NXPing();
			[toolpanel_i	changeTool:SELECT_TOOL];
			if ([self	scanForErrors])
				NXRunAlertPanel("Errors!",
					"Don't run your project, you have some errors. ",
					"OK",NULL,NULL);
			[editworld_i	saveWorld:NULL];
			#if 0
			else
				NXRunAlertPanel("Important!",
					"Save again sometime soon, as Player 1's position was "
					"modified so you could launch your project.",
					"OK",NULL,NULL);
			#endif
			break;
		}
	
	return self;
}

//============================================================================

/*
================
=
= mouseDown:
=
================
*/

#ifdef REDOOMED
// Cocoa version
- (void) mouseDown:(NSEvent *)thisEvent
#else // Original
- mouseDown:(NXEvent *)thisEvent
#endif
{
	int	tool;
		
	tool = [toolpanel_i currentTool];
	
	switch ( tool )
	{
	case SELECT_TOOL:
		[self pointSelect: thisEvent];
		break;
	case LINE_TOOL:
		[self lineDrag: thisEvent];
		break;
	case POLY_TOOL:
		[self polyDrag: thisEvent];
		break;
	case ZOOMIN_TOOL:
		[self zoomIn: thisEvent];
		break;
	case SLIDE_TOOL:
		[self slideView: thisEvent];
		break;
	case THING_TOOL:
		[self placeThing: thisEvent];
		break;
	case GET_TOOL:
		[self getSector: thisEvent];
		break;
	case LAUNCH_TOOL:
		[self	launchAndSave:thisEvent];
		break;
	default:
		break;
	}
			
	[editworld_i updateWindows];

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return(self);
#endif
}

#ifdef REDOOMED
// Cocoa version
- (void) rightMouseDown:(NSEvent *)thisEvent
#else // Original
- rightMouseDown:(NXEvent *)thisEvent
#endif
{
	switch ( [toolpanel_i currentTool] )
	{
	case ZOOMIN_TOOL:
		[self zoomOut: thisEvent];
		break;
	case GET_TOOL:
		[self fillSector:thisEvent];
		break;
	default:
		break;
	}

	[editworld_i updateWindows];

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

//=============================================================================

/*
===============
=
= keyDown:
=
===============
*/

#ifdef REDOOMED
// Cocoa version
- (void) keyDown:(NSEvent *)theEvent
#else // Original
- keyDown:(NXEvent *)theEvent
#endif
{
#ifdef REDOOMED
	if ([[theEvent characters] characterAtIndex: 0] == NSDeleteCharacter)
#else // Original
	if (theEvent->data.key.charCode == 127)
#endif
	{
		[editworld_i delete: self];

#ifdef REDOOMED
		return; // Cocoa version doesn't return a value
#else // Original
		return self;
#endif
	}

#ifdef REDOOMED
    // allow the user to switch tools on the tool panel using hotkeys (while the map window's
    // the key window) using a ToolPanel (RDEUtilities) method that manually forwards a keyDown
    // event to the tool panel's tool button matrix
    if ([toolpanel_i rdePerformToolMatrixKeyEquivalent: theEvent])
    {
        return;
    }
#endif
		
	[editworld_i updateWindows];

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

@end