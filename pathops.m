#import "pathops.h"
#import "PreferencePanel.h"
#import "ps_quartz.h"
//#import "wraps.h"

#if 0

void PSWHitPath(const float HPts[], int Tot_HPts, const char HOps[], int Tot_HOps, const float Pts[], int Tot_Pts, const char Ops[], int Tot_Ops, int *Hit);

#define LINETYPES	16
#define MAXLINES	100
#define MAXPOINTS	(MAXLINES*2)

float		coords[LINETYPES][MAXPOINTS*2], *coord_p[LINETYPES];
char		ops[LINETYPES][MAXPOINTS], *ops_p[LINETYPES], *stopop[LINETYPES];
float		bbox[LINETYPES][4];

void		FinishPath (int path);


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
	size_t	count;
	
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


#define	RECTPTS	12
#define	LINEPTS		8
#define	RECTOPS	6
#define	LINEOPS		3

BOOL	LineInRect (NSPoint *p1, NSPoint *p2, NSRect *r)
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

#endif

// Code taken and adapted from https://stackoverflow.com/a/5514619
static BOOL LineIntersectsLine(NSPoint l1p1, NSPoint l1p2, NSPoint l2p1, NSPoint l2p2)
{
	CGFloat q = (l1p1.y - l2p1.y) * (l2p2.x - l2p1.x) - (l1p1.x - l2p1.x) * (l2p2.y - l2p1.y);
	CGFloat d = (l1p2.x - l1p1.x) * (l2p2.y - l2p1.y) - (l1p2.y - l1p1.y) * (l2p2.x - l2p1.x);
	
	if( d == 0 )
	{
		return NO;
	}
	
	CGFloat r = q / d;
	
	q = (l1p1.y - l2p1.y) * (l1p2.x - l1p1.x) - (l1p1.x - l2p1.x) * (l1p2.y - l1p1.y);
	CGFloat s = q / d;
	
	if( r < 0 || r > 1 || s < 0 || s > 1 )
	{
		return NO;
	}
	
	return YES;
}

// Code taken from https://stackoverflow.com/a/17762050
BOOL EDLineInRect(NSPoint lineStart, NSPoint lineEnd, NSRect rect)
{
	
	/*Test whether the line intersects any of:
	 *- the bottom edge of the rectangle
	 *- the right edge of the rectangle
	 *- the top edge of the rectangle
	 *- the left edge of the rectangle
	 *- the interior of the rectangle (both points inside)
	 */
	
	return (LineIntersectsLine(lineStart, lineEnd, rect.origin, CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)) ||
			LineIntersectsLine(lineStart, lineEnd, CGPointMake(rect.origin.x + rect.size.width, rect.origin.y), CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)) ||
			LineIntersectsLine(lineStart, lineEnd, CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height), CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)) ||
			LineIntersectsLine(lineStart, lineEnd, CGPointMake(rect.origin.x, rect.origin.y + rect.size.height), rect.origin) ||
			(CGRectContainsPoint(rect, lineStart) && CGRectContainsPoint(rect, lineEnd)));
}

