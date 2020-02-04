// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "pathops.h"
#import "PreferencePanel.h"

#ifndef REDOOMED // Original (Disable for ReDoomEd - unused)
#   import "wraps.h"
#endif

#define LINETYPES	16
#define MAXLINES	100
#define MAXPOINTS	(MAXLINES*2)

float		coords[LINETYPES][MAXPOINTS*2], *coord_p[LINETYPES];
DPSUserPathOp		ops[LINETYPES][MAXPOINTS], *ops_p[LINETYPES], *stopop[LINETYPES];
float		bbox[LINETYPES][4];

void		FinishPath (int path);

#ifdef REDOOMED
// utility functions used by ReDoomEd's reimplementation of the LineInRect() function
static BOOL RDE_LineIntersectsHorizontalSegment(NSPoint lineEndpoint1,
                                                NSPoint lineEndpoint2,
                                                float horizontalSegmentY,
                                                float horizontalSegmentStartX,
                                                float horizontalSegmentEndX);
                                                
static BOOL RDE_LineIntersectsVerticalSegment(NSPoint lineEndpoint1,
                                                NSPoint lineEndpoint2,
                                                float verticalSegmentX,
                                                float verticalSegmentStartY,
                                                float verticalSegmentEndY);
#endif // REDOOMED


/*
==============
=
= StartPath
=
==============
*/

void		StartPath (int path)
{
	bbox[path][0] = -MAXFLOAT/2;
	bbox[path][1] = -MAXFLOAT/2;
	bbox[path][2] = MAXFLOAT/2;
	bbox[path][3] = MAXFLOAT/2;
	
	coord_p[path] = coords[path];
	ops_p[path] = ops[path];
	stopop[path] = &ops[path][MAXPOINTS];
}


/*
==============
=
= AddLine
=
==============
*/

void		AddLine (int path, float x1, float y1, float x2, float y2)
{
	float	*box;
	
	box = bbox[path];
	
	x1 = x1+0.5;
	y1 = y1+0.5;
	x2 = x2+0.5;
	y2 = y2+0.5;
	
	if (x1 < box[0])
		box[0] = x1;
	if (x1 > box[2])
		box[2] = x1;
	if (x2 < box[0])
		box[0] = x2;
	if (x2 > box[2])
		box[2] = x2;
		
	if (y1 < box[1])
		box[1] = y1;
	if (y1 > box[3])
		box[3] = y1;
	if (y2 < box[1])
		box[1] = y2;
	if (y2 > box[2])
		box[3] = y2;
		
	*ops_p[path]++ = dps_moveto;
	*coord_p[path]++ = x1;
	*coord_p[path]++ = y1;
	*ops_p[path]++ = dps_lineto;
	*coord_p[path]++ = x2;
	*coord_p[path]++ = y2;
	
	if (ops_p[path] == stopop[path])
	{	// buffer is full, write out what we have and start over
		FinishPath (path);
		StartPath (path);
	}
}


/*
==============
=
= FinishPath
=
==============
*/

void		FinishPath (int path)
{
	int	count;
	
	count = ops_p[path] - ops[path];
	if (!count)
		return;		// nothing in list
		
	bbox[path][0] -= 1.0;
	bbox[path][1] -= 1.0;
	bbox[path][2] += 1.0;
	bbox[path][3] += 1.0;
	
	NXSetColor ([prefpanel_i colorFor: path]);
	DPSDoUserPath(coords[path], count*2, dps_float, ops[path], count, bbox[path], dps_ustroke);
}


/*
==============
=
= LineInRect
=
==============
*/

#ifdef REDOOMED
//  Reimplemented LineInRect() so it doesn't use PSWHitPath(), which is undefined in ReDoomEd.
// (PSWHitPath() is a PostScript function that checks if two paths touch - there's no
// corresponding functionality in Cocoa's NSBezierPath).
//  The new version uses the RDE utility functions, RDE_LineIntersectsHorizontalSegment() &
// RDE_LineIntersectsVerticalSegment(), defined below.

BOOL LineInRect(NXPoint *p1, NXPoint *p2, NXRect *r)
{
    if (NSPointInRect(*p1, *r) || NSPointInRect(*p2, *r))
    {
        return YES;
    }

    if (((p1->x >= NSMaxX(*r)) && (p2->x >= NSMaxX(*r)))
        || ((p1->x < r->origin.x) && (p2->x < r->origin.x))
        || ((p1->y >= NSMaxY(*r)) && (p2->y >= NSMaxY(*r)))
        || ((p1->y < r->origin.y) && (p2->y < r->origin.y)))
    {
        return NO;
    }

    if (RDE_LineIntersectsHorizontalSegment(*p1, *p2, NSMaxY(*r), r->origin.x, NSMaxX(*r))
        || RDE_LineIntersectsHorizontalSegment(*p1, *p2, r->origin.y, r->origin.x, NSMaxX(*r))
        || RDE_LineIntersectsVerticalSegment(*p1, *p2, r->origin.x, r->origin.y, NSMaxY(*r))
        || RDE_LineIntersectsVerticalSegment(*p1, *p2, NSMaxX(*r), r->origin.y, NSMaxY(*r)))
    {
        return YES;
    }

    return NO;
}

#else // Original

#define	RECTPTS	12
#define	LINEPTS		8
#define	RECTOPS	6
#define	LINEOPS		3

BOOL	LineInRect (NXPoint *p1, NXPoint *p2, NXRect *r)
{
	float		rectpts[RECTPTS];
	float		linepts[LINEPTS];
	char		rectops[RECTOPS];
	char		lineops[LINEOPS];
	int		hit;
	
//
// build a user path for the rectangle
//
	rectops[0] = dps_setbbox;
	rectpts[0] = r->origin.x-1;
	rectpts[1] = r->origin.y-1;
	rectpts[2] = r->origin.x+r->size.width+1;
	rectpts[3] = r->origin.y+r->size.height+1;
	
	rectops[1] = dps_moveto;
	rectpts[4] = r->origin.x;
	rectpts[5] = r->origin.y;

	rectops[2] = dps_rlineto;
	rectpts[6] = r->size.width;
	rectpts[7] = 0;

	rectops[3] = dps_rlineto;
	rectpts[8] = 0;
	rectpts[9] = r->size.height;

	rectops[4] = dps_rlineto;
	rectpts[10] = -r->size.width;
	rectpts[11] = 0;

	rectops[5] = dps_closepath;

//
// build a user path for the line
//
	lineops[0] = dps_setbbox;
	if (p1->x < p2->x)
	{
		linepts[0] = p1->x-1;
		linepts[2] = p2->x+1;
	}
	else
	{
		linepts[0] = p2->x-1;
		linepts[2] = p1->x+1;
	}
	if (p1->y < p2->y)
	{
		linepts[1] = p1->y-1;
		linepts[3] = p2->y+1;
	}
	else
	{
		linepts[1] = p2->y-1;
		linepts[3] = p1->y+1;
	}
	
	lineops[1] = dps_moveto;
	linepts[4] = p1->x;
	linepts[5] = p1->y;

	lineops[2] = dps_lineto;
	linepts[6] = p2->x;
	linepts[7] = p2->y;

//
// test for intersection
//
	PSWHitPath (rectpts, RECTPTS, rectops, RECTOPS
	, linepts, LINEPTS, lineops, LINEOPS, &hit);
		
	return hit;
}

#endif // Original

#ifdef REDOOMED
// RDE_LineIntersectsHorizontalSegment() & RDE_LineIntersectsVerticalSegment():
// utility functions used by ReDoomEd's reimplementation of the LineInRect() function

static BOOL RDE_LineIntersectsHorizontalSegment(NSPoint lineEndpoint1,
                                            NSPoint lineEndpoint2,
                                            float horizontalSegmentY,
                                            float horizontalSegmentStartX,
                                            float horizontalSegmentEndX)
{
    NSPoint lineVector;
    float intersectionX;

    if (((lineEndpoint1.y < horizontalSegmentY) && (lineEndpoint2.y < horizontalSegmentY))
        || ((lineEndpoint1.y > horizontalSegmentY) && (lineEndpoint2.y > horizontalSegmentY)))
    {
        return NO;
    }

    if (horizontalSegmentStartX > horizontalSegmentEndX)
    {
        float temp = horizontalSegmentStartX;
        horizontalSegmentStartX = horizontalSegmentEndX;
        horizontalSegmentEndX = temp;
    }

    if (((lineEndpoint1.x < horizontalSegmentStartX)
            && (lineEndpoint2.x < horizontalSegmentStartX))
        || ((lineEndpoint1.x > horizontalSegmentEndX)
            && (lineEndpoint2.x > horizontalSegmentEndX)))
    {
        return NO;
    }

    if (lineEndpoint1.y == lineEndpoint2.y)
    {
        return YES;
    }

    lineVector = NSMakePoint(lineEndpoint2.x - lineEndpoint1.x,
                            lineEndpoint2.y - lineEndpoint1.y);

    intersectionX =
        lineEndpoint1.x + lineVector.x * (horizontalSegmentY - lineEndpoint1.y) / lineVector.y;

    if ((intersectionX < horizontalSegmentStartX) || (intersectionX > horizontalSegmentEndX))
    {
        return NO;
    }

    return YES;
}

static BOOL RDE_LineIntersectsVerticalSegment(NSPoint lineEndpoint1,
                                            NSPoint lineEndpoint2,
                                            float verticalSegmentX,
                                            float verticalSegmentStartY,
                                            float verticalSegmentEndY)
{
    NSPoint lineVector;
    float intersectionY;

    if (((lineEndpoint1.x < verticalSegmentX) && (lineEndpoint2.x < verticalSegmentX))
        || ((lineEndpoint1.x > verticalSegmentX) && (lineEndpoint2.x > verticalSegmentX)))
    {
        return NO;
    }

    if (verticalSegmentStartY > verticalSegmentEndY)
    {
        float temp = verticalSegmentStartY;
        verticalSegmentStartY = verticalSegmentEndY;
        verticalSegmentEndY = temp;
    }

    if (((lineEndpoint1.y < verticalSegmentStartY)
            && (lineEndpoint2.y < verticalSegmentStartY))
        || ((lineEndpoint1.y > verticalSegmentEndY)
            && (lineEndpoint2.y > verticalSegmentEndY)))
    {
        return NO;
    }

    if (lineEndpoint1.x == lineEndpoint2.x)
    {
        return YES;
    }

    lineVector = NSMakePoint(lineEndpoint2.x - lineEndpoint1.x,
                            lineEndpoint2.y - lineEndpoint1.y);

    intersectionY =
        lineEndpoint1.y + lineVector.y * (verticalSegmentX - lineEndpoint1.x) / lineVector.x;

    if ((intersectionY < verticalSegmentStartY) || (intersectionY > verticalSegmentEndY))
    {
        return NO;
    }

    return YES;
}

#endif // REDOOMED
