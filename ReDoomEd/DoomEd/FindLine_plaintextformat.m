// REDOOMED: This file is a modified copy of FindLine.m, reformatted as plain-text for use with
// current compilers. (The original FindLine.m is in rich-text format).

// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"EditWorld.h"
#import "FindLine.h"

@implementation FindLine

//=============================================================
//
//	Find Line init
//
//=============================================================
- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	window_i = NULL;
	delSound = [[NSSound soundNamed:@"D_EPain"] retain];
    return self;
}

//=============================================================
//
//	Pop up the window from the menu
//
//=============================================================
- (IBAction)menuTarget:sender
{
	if (!window_i)
	{
		[NXApp 
			loadNibSection:	"FindLine.nib"
			owner:			self
			withNames:		NO
		];
		
#ifdef REDOOMED
		[status_i	setStringValue:@" "];
#else // Original
		[status_i	setStringValue:" "];
#endif
		[window_i	setFrameUsingName:PREFNAME];
	}
	[window_i	makeKeyAndOrderFront:self];
}

/// Find the line and scroll it to center
- (IBAction)findLine:sender
{
	NSInteger		linenum;
	NXRect			r;
	worldline_t		*l;
	id				window;
	
	linenum = [numfield_i	intValue];
	if ([fromBSP_i	intValue])
		linenum = [self	getRealLineNum:(int)linenum];
#ifdef REDOOMED
	// Bugfix: validate linenum value
	else if (linenum >= numlines)
	{
		linenum = NSNotFound;
	}
#endif

	if (linenum == NSNotFound)
	{
#ifdef REDOOMED
		[status_i	setStringValue:@"No such line!"];
#else // Original
		[status_i	setStringValue:"No such line!"];
#endif
		return;
	}
	
	[editworld_i	selectLine:(int)linenum];
	[editworld_i	selectPoint:lines[linenum].p1];
	[editworld_i	selectPoint:lines[linenum].p2];
	
	l = &lines[linenum];
	[self	rectFromPoints:&r p1:points[l->p1].pt p2:points[l->p2].pt];
	window = [editworld_i	getMainWindow];
	r.origin.x -= MARGIN;
	r.origin.y -= MARGIN;
	r.size.width += MARGIN*2;
	r.size.height += MARGIN*2;

#ifdef REDOOMED
	// Cocoa's scrollRectToVisible: takes a value, not a pointer
	[[[window	contentView] documentView] scrollRectToVisible:r];
	[editworld_i	redrawWindows];
	[status_i	setStringValue:@"Found it!"];
#else // Original
	[[[window	contentView] docView] scrollRectToVisible:&r];
	[editworld_i	redrawWindows];
	[status_i	setStringValue:"Found it!"];
#endif
}

/// Delete the line
- (IBAction)deleteLine:sender
{
	NSInteger	linenum;
#ifdef REDOOMED
	worldline_t	line;
#endif
	
	linenum = [numfield_i	intValue];
	if ([fromBSP_i	intValue])
		linenum = [self	getRealLineNum:(int)linenum];
#ifdef REDOOMED
	// Bugfix: validate linenum value
	else if (linenum >= numlines)
	{
		linenum = NSNotFound;
	}
#endif

	if (linenum == NSNotFound)
	{
#ifdef REDOOMED
		[status_i	setStringValue:NSLocalizedString(@"No such line!", @"No such line!")];
#else // Original
		[status_i	setStringValue:"No such line!"];
#endif

		return;
	}
	
	[editworld_i	selectLine:linenum];
	[editworld_i	selectPoint:lines[linenum].p1];
	[editworld_i	selectPoint:lines[linenum].p2];
	
#ifdef REDOOMED
	// Bugfix: fixed line removal - copied line-deletion code from -[EditWorld delete:] (now
	// decrements the reference counts of the line's endpoints, and redraws the mapview)
	line = lines[linenum];
	line.selected = -1;	// remove the line
	[editworld_i changeLine: (int)linenum to: &line];
	[editworld_i updateWindows];
#else // Original
	lines[linenum].selected = -1;
#endif

#ifdef REDOOMED
	[status_i	setStringValue:NSLocalizedString(@"Toasted it!", @"Toasted it!")];
#else // Original
	[status_i	setStringValue:"Toasted it!"];
#endif

	[delSound play];
}

///	Skip all the deleted lines in the list and find the correct one
- (NSInteger)getRealLineNum:(int)num
{
	int	index;
	int	i;
	
	index = 0;
	for (i = 0;i < numlines;i++)
	{
		if (index == num)
			return i;
		if (lines[i].selected != -1)
			index++;
	}
	
	return NSNotFound;
}

///	Wow, this needed to be written.
- (void)rectFromPoints:(NXRect *)r p1:(NXPoint)p1 p2:(NXPoint)p2
{
	if (p1.x < p2.x)
	{
		r->origin.x = p1.x;
		r->size.width = p2.x - p1.x;
	}
	else
	{
		r->origin.x = p2.x;
		r->size.width = p1.x - p2.x;
	}
	
	if (p1.y < p2.y)
	{
		r->origin.y = p1.y;
		r->size.height = p2.y - p1.y;
	}
	else
	{
		r->origin.y = p2.y;
		r->size.height = p1.y - p2.y;
	}
}

- appWillTerminate:sender
{
	if (window_i)
		[window_i	saveFrameUsingName:PREFNAME];
	return self;
}

@end
