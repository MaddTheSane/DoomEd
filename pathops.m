#import "pathops.h"
#import "PreferencePanel.h"
#import "ps_quartz.h"
//#import "wraps.h"



#define LINETYPES	16
#define MAXLINES	100
#define MAXPOINTS	(MAXLINES*2)

static NSBezierPath *paths[LINETYPES];


/*
==============
=
= StartPath
=
==============
*/

void		StartPath (int path)
{
	paths[path] = [[NSBezierPath alloc] init];
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
	NSBezierPath *mainPath = paths[path];
	[mainPath moveToPoint:NSMakePoint(x1, y1)];
	[mainPath lineToPoint:NSMakePoint(x2, y2)];
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
	NSBezierPath *mainPath = paths[path];
	
	[[prefpanel_i colorFor: path] set];
	[mainPath stroke];
	[mainPath release];
	paths[path] = nil;
}

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

