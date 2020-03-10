// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#include <tgmath.h>
#import "idfunctions.h"
#import "LinePanel.h"
#import "SpecialList.h"
#import "TexturePalette.h"
#import "R_mapdef.h"
#import	"DoomProject.h"

LinePanel *linepanel_i;
SpecialList *lineSpecialPanel_i;

@implementation LinePanel

/*
=====================
=
= init
=
=====================
*/

- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	linepanel_i = self;
	window_i = NULL;		// until nib is loaded

	memset (&baseline, 0, sizeof(baseline));
	baseline.flags = ML_BLOCKMOVE;
	baseline.p1 = baseline.p2 = -1;
	strcpy (baseline.side[0].toptexture, "T1");
	strcpy (baseline.side[0].bottomtexture, "T1");
	strcpy (baseline.side[0].midtexture, "T1");
	baseline.side[0].ends.floorheight = 0;
	baseline.side[0].ends.ceilingheight = 80;
	strcpy (baseline.side[0].ends.floorflat, "FLAT1");
	strcpy (baseline.side[0].ends.ceilingflat, "FLAT2");
	
	memcpy (&baseline.side[1], &baseline.side[0], sizeof(baseline.side[0]));
	
#ifdef REDOOMED
	// - Added missing init call
	// - Added (SpecialList *) typecast so the compiler uses the correct method signature
	lineSpecialPanel_i = [[SpecialList alloc] init];
	[lineSpecialPanel_i setSpecialTitle:"Line Inspector - Specials"];
	[lineSpecialPanel_i setFrameName:@"LineSpecialPanel"];
	[lineSpecialPanel_i setDelegate:self];
#else // Original
	lineSpecialPanel_i = [[[[SpecialList	alloc]
					setSpecialTitle:"Line Inspector - Specials"]
					setFrameName:"LineSpecialPanel"]
					setDelegate:self];
#endif

	return self;
}

- (void)emptySpecialList
{
	[lineSpecialPanel_i	empty];
}

- (void)saveFrame
{
	[lineSpecialPanel_i	saveFrame];

#ifdef REDOOMED
	if (firstColCalc_i)
		[firstColCalc_i		saveFrameUsingName:@"FirstColCalc"];
	if (window_i)
		[window_i	saveFrameUsingName:@"LineInspector"];
#else // Original
	if (firstColCalc_i)
		[firstColCalc_i		saveFrameUsingName:"FirstColCalc"];
	if (window_i)
		[window_i	saveFrameUsingName:"LineInspector"];
#endif
}

- (void)specialChosen:(int)value
{
	[special_i		setIntValue:value];
	[self	specialChanged:NULL];
}

- (void)updateLineSpecialsDSP:(FILE *)stream
{
	[lineSpecialPanel_i	updateSpecialsDSP:stream];
}

- (IBAction)activateSpecialList:sender
{
	[lineSpecialPanel_i	displayPanel];
}

/*
==============
=
= menuTarget:
=
==============
*/

- (void)menuTarget:sender
{
	if (!window_i)
	{
		[NXApp 
			loadNibSection:	"line.nib"
			owner:			self
			withNames:		NO
		];

#ifdef REDOOMED
		// NSTextFields don't send their action message if their window resigns key while
		// they're being edited, and the text changes will be lost if the textfield's
		// content is changed programmatically before the window becomes key again;
		// to avoid losing the user's input, make edited textfields send their action
		// immediately if the panel resigns key
		[window_i rdeSetupTextfieldsToSendActionWhenPanelResignsKey];

		[window_i	setFrameUsingName:@"LineInspector"];
		[firstColCalc_i		setFrameUsingName:@"FirstColCalc"];
#else // Original
		[window_i	setFrameUsingName:"LineInspector"];
		[firstColCalc_i		setFrameUsingName:"FirstColCalc"];
#endif
	}

#ifdef REDOOMED
	// the LinePanel's control values may be out of date, since LinePanel's implementation
	// of the windowDidUpdate: delegate method (below) is disabled for ReDoomEd (Cocoa
	// calls that delegate method too often - during every event - even preventing
	// textfields from being edited because windowDidUpdate:'s call to updateInspector:
	// restores all textfields to their current (pre-edit) values after each keypress
	// event), and other calls to updateInspector: pass NO (don't update if the panel's
	// hidden), so an updateInspector: call was added here, passing YES to force the panel
	// to update before showing it.
	[self updateInspector: YES];
#endif

	[window_i orderFront:self];
}

/*
==============
=
= sideRadioTarget:
=
==============
*/

- (IBAction)sideRadioTarget:sender
{
	[self updateInspector: NO];
}



/*
==================
=
= getSide:
=
= Sets variables in side from a form object
==================
*/

- getSide: (worldside_t *)side
{
	side->flags = [sideform_i intValueAt: 0];
	side->firstcollumn = [sideform_i intValueAt: 1];

#ifdef REDOOMED
	// Bugfix: strncpy() may leave unterminated strings; replaced with
	// macroRDE_SafeCStringCopy() to ensure the strings are terminated
	macroRDE_SafeCStringCopy(side->toptexture, [sideform_i stringValueAt: 2]);
	macroRDE_SafeCStringCopy(side->midtexture, [sideform_i stringValueAt: 3]);
	macroRDE_SafeCStringCopy(side->bottomtexture, [sideform_i stringValueAt: 4]);
#else // Original
	strncpy (side->toptexture, [sideform_i stringValueAt: 2], 9);
	strncpy (side->midtexture, [sideform_i stringValueAt: 3], 9);
	strncpy (side->bottomtexture, [sideform_i stringValueAt: 4], 9);
#endif

	memset (&side->ends,0,sizeof(side->ends));

	return self;
}

/*
==================
=
= setSide:
=
= Sets fields in a form object based on a mapside structure
==================
*/

- setSide: (worldside_t *)side
{
	[sideform_i setIntValue: side->flags at: 0] ;
	[sideform_i setIntValue: side->firstcollumn at: 1];
	[sideform_i setStringValue: side->toptexture at: 2];
	[sideform_i setStringValue: side->midtexture at: 3];
	[sideform_i setStringValue: side->bottomtexture at: 4];

	return self;
}


/*
==============
=
= updateInspector
=
= call with force == YES to update into a window while it is off screen, otherwise
= no updating is done if not visible
=
==============
*/

- (void)updateInspector: (BOOL)force
{
	NSInteger		side;
	worldline_t	*line;
	int		xlen;
	int		ylen;
	int		dlen;

	if (!window_i)
		return;
		
	if (!force && ![window_i isVisible])
		return;

	[window_i disableFlushWindow];
	
	line = &baseline;
	
	//
	// write values out
	//
	[p1_i setIntValue: line->p1];
	[p2_i setIntValue: line->p2];
	
	[special_i setIntValue: line->special];
	[tagField_i setIntValue: line->tag];
	
	[dontdraw_i		setState: (line->flags&ML_DONTDRAW) > 0];
	[monsterblock_i	setState: (line->flags&ML_MONSTERBLOCK) > 0];
	[soundblock_i	setState: (line->flags&ML_SOUNDBLOCK) > 0];
	[secret_i	setState:	(line->flags&ML_SECRET) > 0];
	[pblock_i setState:  (line->flags&ML_BLOCKMOVE) > 0];
	[toppeg_i setState:  (line->flags&ML_DONTPEGTOP) > 0];
	[bottompeg_i setState:  (line->flags&ML_DONTPEGBOTTOM) > 0];
	[twosided_i setState:  (line->flags&ML_TWOSIDED) > 0];

	side = [sideradio_i selectedColumn];
	[self setSide: &line->side[side]];
	
	//
	//	Calc line length
	//
	xlen = fabs(points[line->p2].pt.x - points[line->p1].pt.x);
	xlen = xlen*xlen;
	ylen = fabs(points[line->p2].pt.y - points[line->p1].pt.y);
	ylen = ylen*ylen;
	dlen = sqrt(xlen + ylen);
	[linelength_i	setIntValue:dlen];

	[window_i reenableFlushWindow];

#ifdef REDOOMED
	// avoid unnecessary flushing
	[window_i flushWindowIfNeeded];
#else // Original
	[window_i flushWindow];
#endif
}

//============================================================================


- (void)changeLineFlag: (mapline_flags)mask to: (mapline_flags)set
{
	int	i;
#ifdef REDOOMED
	// use line as a local copy of a lines[] entry rather than a pointer to the entry
	worldline_t	line;
#else // Original
	worldline_t	*line;
#endif
	
	for (i=0 ; i<numlines ; i++)
		if (lines[i].selected > 0)
		{
#ifdef REDOOMED
			// -[EditWorld changeLine:to:] now sets the mapdirty flag, but only if the line
			// passed to it doesn't match the entry at lines[i], so rather than modifying
			// lines[i] before the call (which would trick changeLine:to: into not setting the
			// mapdirty flag), change a local copy of the line & pass the copy to changeLine:to:.
			line = lines[i];
			line.flags &= mask;
			line.flags |= set;
			[editworld_i changeLine: i to: &line];
#else // Original
			line = &lines[i];
			line->flags &= mask;
			line->flags |= set;
			[editworld_i changeLine: i to: line];
#endif
		}
		
	[editworld_i updateWindows];
}

- (IBAction)monsterblockChanged: sender
{
	NSControlStateValue	state;
	state = [monsterblock_i state];	
	[self changeLineFlag: ~ML_MONSTERBLOCK  to: ML_MONSTERBLOCK*state];
}

- (IBAction)blockChanged: sender
{
	NSControlStateValue	state;
	state = [pblock_i state];	
	[self changeLineFlag: ~ML_BLOCKMOVE  to: ML_BLOCKMOVE*state];
}

- (IBAction)secretChanged:sender
{
	NSControlStateValue	state;
	state = [secret_i	state];
	[self	changeLineFlag: ~ML_SECRET	to:ML_SECRET*state];
}

- (IBAction)dontDrawChanged:sender
{
	NSControlStateValue	state;
	state = [dontdraw_i	state];
	[self	changeLineFlag: ~ML_DONTDRAW	to:ML_DONTDRAW*state];
}

- (IBAction)soundBlkChanged:sender
{
	NSControlStateValue	state;
	state = [soundblock_i	state];
	[self	changeLineFlag: ~ML_SOUNDBLOCK	to:ML_SOUNDBLOCK*state];
}

- (IBAction)twosideChanged: sender
{
	NSControlStateValue	state;
	state = [twosided_i state];	
	[self changeLineFlag: ~ML_TWOSIDED  to: ML_TWOSIDED*state];
}

- (IBAction)toppegChanged: sender
{
	NSControlStateValue	state;
	state = [toppeg_i state];	
	[self changeLineFlag: ~ML_DONTPEGTOP  to: ML_DONTPEGTOP*state];
}

- (IBAction)bottompegChanged: sender
{
	NSControlStateValue	state;
	state = [bottompeg_i state];	
	[self changeLineFlag: ~ML_DONTPEGBOTTOM  to: ML_DONTPEGBOTTOM*state];
}

- (IBAction)specialChanged: sender
{
	int		i,value;
#ifdef REDOOMED
	worldline_t line;
#endif
	
	value = [special_i intValue];	
	for (i=0 ; i<numlines ; i++)
		if (lines[i].selected > 0)
		{
#ifdef REDOOMED
			// -[EditWorld changeLine:to:] now sets the mapdirty flag, but only if the line
			// passed to it doesn't match the entry at lines[i], so rather than modifying
			// lines[i] before the call (which would trick changeLine:to: into not setting the
			// mapdirty flag), change a local copy of the line & pass the copy to changeLine:to:.
			line = lines[i];
			line.special = value;
			[editworld_i changeLine: i to: &line];
#else // Original
			lines[i].special = value;
			[editworld_i changeLine: i to: &lines[i]];
#endif
		}
	
	[lineSpecialPanel_i	setSpecial:[special_i	intValue]];
	[editworld_i updateWindows];
}


- (IBAction)tagChanged: sender
{
	int		i,value;
#ifdef REDOOMED
	worldline_t line;
#endif
	
	value = [tagField_i intValue];	
	for (i=0 ; i<numlines ; i++)
		if (lines[i].selected > 0)
		{
#ifdef REDOOMED
			// -[EditWorld changeLine:to:] now sets the mapdirty flag, but only if the line
			// passed to it doesn't match the entry at lines[i], so rather than modifying
			// lines[i] before the call (which would trick changeLine:to: into not setting the
			// mapdirty flag), change a local copy of the line & pass the copy to changeLine:to:.
			line = lines[i];
			line.tag = value;
			[editworld_i changeLine: i to: &line];
#else // Original
			lines[i].tag = value;
			[editworld_i changeLine: i to: &lines[i]];
#endif
		}
	
	[editworld_i updateWindows];
}


- (IBAction)sideChanged: sender
{
	NSInteger		i,side;
	worldside_t	new;
	worldline_t	*line;
	
	side = [sideradio_i selectedColumn];
	[self getSide: &new];
	for (i=0 ; i<numlines ; i++)
		if (lines[i].selected > 0)
		{
			line = &lines[i];
			new.ends = line->side[side].ends;
			line->side[side] = new;
			[editworld_i changeLine: i to: line];
			[doomproject_i	setMapDirty:TRUE];
		}
	
	[editworld_i updateWindows];
}

- (IBAction)getFromTP:sender
{
	NSInteger	tag;
	
	tag = [[sender selectedCell] tag];

#ifdef REDOOMED
	[[sideform_i	cellAtRow:2+tag column:0]
		setStringValue:RDE_NSStringFromCString([texturePalette_i  getSelTextureName])];
#else // Original
	[[sideform_i	cellAt:2+tag :0]
		setStringValue:[texturePalette_i  getSelTextureName]];
#endif

	[self	sideChanged:NULL];
}

- (IBAction)setTP:sender
{
	NSInteger	tag;
	
	tag = [[sender selectedCell] tag];

#ifdef REDOOMED
	[texturePalette_i
	    setSelTexture:
	 (char *)RDE_CStringFromNSString([[sideform_i cellAtRow:2+tag column:0] stringValue])];
#else // Original
	[texturePalette_i	setSelTexture:(char *)[[sideform_i cellAt:2+tag :0] stringValue]];
#endif
}

- (IBAction)zeroEntry:sender
{
	NSInteger tag;
	
	tag = [[sender selectedCell] tag];

#ifdef REDOOMED
	[[sideform_i	cellAtRow:2+tag column:0] setStringValue:@"-"];
#else // Original
	[[sideform_i	cellAt:2+tag :0] setStringValue:"-"];
#endif

	[self	sideChanged:NULL];
}

//==========================================================
//
// Suggest a new tag value for this map
//
//==========================================================
- (IBAction)suggestTagValue:sender
{
	int	i, val, found;
	
	for (val = 0;val <10000; val++)
	{
		found = 0;
		// CHECK LINES
		for (i = 0;i < numlines;i++)
			if (lines[ i ].tag == val)
			{
				found = 1;
				break;
			}	
		if (!found)
		{
			[tagField_i	setIntValue:val];
			[self	tagChanged:NULL];
			break;
		}
	}
}

- (int)getTagValue
{
	return	[tagField_i	intValue];
}

//==========================================================
//
//	Firstcol Calculator code
//
//==========================================================
- (void)popUpCalc:sender
{
	[firstColCalc_i		makeKeyAndOrderFront:NULL];
}

- (IBAction)setFCVal:sender
{
	[fc_currentVal_i setIntValue:[[sideform_i cellAtRow:1 column:0] intValue]];
}

- (IBAction)incFirstCol:sender
{
	int	val;
	val = [fc_currentVal_i	intValue];
	val += [fc_incDec_i	intValue];
	[fc_currentVal_i	setIntValue:val];
	[[sideform_i cellAtRow:1 column:0]  setIntValue:val];
	[self	sideChanged:NULL];
}

- (IBAction)decFirstCol:sender
{
	int	val;
	val = [fc_currentVal_i	intValue];
	val -= [fc_incDec_i	intValue];
	[fc_currentVal_i	setIntValue:val];
	[[sideform_i cellAtRow:1 column:0]  setIntValue:val];
	[self	sideChanged:NULL];
}


//============================================================================


/*
==============
=
= updateLineInspector
=
==============
*/

- (void)updateLineInspector
{
	int		i;
	worldline_t	*line;
		
	line = &lines[0];
	for (i=0 ; i<numlines ; i++, line++)
		if (line->selected > 0)
		{
			baseline = *line;
			break;
		}
		
	[special_i		setIntValue:baseline.special];
	if (memcmp(&baseline, &oldline, sizeof(baseline)) )
	{
		memcpy (&oldline, &baseline, sizeof(oldline));
		[self updateInspector: NO];
	}
	
	[self	updateLineSpecial];
}

- (void)updateLineSpecial
{
	int	which;
	
	which = [special_i	intValue];
	[lineSpecialPanel_i	setSpecial:which];
}


/*
===================
=
= windowDidUpdate:
=
===================
*/

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa would call this method too often: every event)
- windowDidUpdate:sender
{
	[self updateInspector: YES];
	return self;
}
#endif


/*
===================
=
= baseLine:
=
= Returns the values currently displayed, so that a new line can be drawn with
= those values
=
===================
*/

- (void)baseLine: (worldline_t *)line
{
	*line = baseline;
}

@end
