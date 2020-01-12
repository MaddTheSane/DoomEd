// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "idfunctions.h"
#import "LinePanel.h"
#import "SpecialList.h"
#import "TexturePalette.h"
#import "R_mapdef.h"
#import	"DoomProject.h"

id	linepanel_i;
id	lineSpecialPanel_i;

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
	lineSpecialPanel_i = [(SpecialList *) [[[[SpecialList alloc] init]
					setSpecialTitle:"Line Inspector - Specials"]
					setFrameName:"LineSpecialPanel"]
					setDelegate:self];
#else // Original
	lineSpecialPanel_i = [[[[SpecialList	alloc]
					setSpecialTitle:"Line Inspector - Specials"]
					setFrameName:"LineSpecialPanel"]
					setDelegate:self];
#endif

	return self;
}

- emptySpecialList
{
	[lineSpecialPanel_i	empty];
	return self;
}

- saveFrame
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

	return self;
}

- specialChosen:(int)value
{
	[special_i		setIntValue:value];
	[self	specialChanged:NULL];
	return self;
}

- updateLineSpecialsDSP:(FILE *)stream
{
	[lineSpecialPanel_i	updateSpecialsDSP:stream];
	return self;
}

- activateSpecialList:sender
{
	[lineSpecialPanel_i	displayPanel];
	return self;
}

/*
==============
=
= menuTarget:
=
==============
*/

- menuTarget:sender
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

	return self;
}

/*
==============
=
= sideRadioTarget:
=
==============
*/

- sideRadioTarget:sender
{
	[self updateInspector: NO];
	return self;
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

- updateInspector: (BOOL)force
{
	int		side;
	worldline_t	*line;
	int		xlen;
	int		ylen;
	int		dlen;

	if (!window_i)
		return self;
		
	if (!force && ![window_i isVisible])
		return self;

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

	side = [sideradio_i selectedCol];	
	[self setSide: &line->side[side]];
	
	//
	//	Calc line length
	//
	xlen = abs(points[line->p2].pt.x - points[line->p1].pt.x);
	xlen = xlen*xlen;
	ylen = abs(points[line->p2].pt.y - points[line->p1].pt.y);
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
	
	return self;
}

//============================================================================


- changeLineFlag: (int)mask to: (int)set
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
	return self;
}

- monsterblockChanged: sender
{
	int	state;
	state = [monsterblock_i state];	
	[self changeLineFlag: ~ML_MONSTERBLOCK  to: ML_MONSTERBLOCK*state];
	return self;
}

- blockChanged: sender
{
	int	state;
	state = [pblock_i state];	
	[self changeLineFlag: ~ML_BLOCKMOVE  to: ML_BLOCKMOVE*state];
	return self;
}

- secretChanged:sender
{
	int	state;
	state = [secret_i	state];
	[self	changeLineFlag: ~ML_SECRET	to:ML_SECRET*state];
	return self;
}

- dontDrawChanged:sender
{
	int	state;
	state = [dontdraw_i	state];
	[self	changeLineFlag: ~ML_DONTDRAW	to:ML_DONTDRAW*state];
	return self;
}

- soundBlkChanged:sender
{
	int	state;
	state = [soundblock_i	state];
	[self	changeLineFlag: ~ML_SOUNDBLOCK	to:ML_SOUNDBLOCK*state];
	return self;
}

- twosideChanged: sender
{
	int	state;
	state = [twosided_i state];	
	[self changeLineFlag: ~ML_TWOSIDED  to: ML_TWOSIDED*state];
	return self;
}

- toppegChanged: sender
{
	int	state;
	state = [toppeg_i state];	
	[self changeLineFlag: ~ML_DONTPEGTOP  to: ML_DONTPEGTOP*state];
	return self;
}

- bottompegChanged: sender
{
	int	state;
	state = [bottompeg_i state];	
	[self changeLineFlag: ~ML_DONTPEGBOTTOM  to: ML_DONTPEGBOTTOM*state];
	return self;
}

- specialChanged: sender
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
	return self;
}


- tagChanged: sender
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
	return self;
}


- sideChanged: sender
{
	int		i,side;
	worldside_t	new;
	worldline_t	*line;
	
	side = [sideradio_i selectedCol];
	[self getSide: &new];
	for (i=0 ; i<numlines ; i++)
		if (lines[i].selected > 0)
		{
			line = &lines[i];
			new.ends = line->side[side].ends;
			line->side[side] = new;
			[editworld_i changeLine: i to: line];
			[doomproject_i	setDirtyMap:TRUE];
		}
	
	[editworld_i updateWindows];
	return self;
}

- getFromTP:sender
{
	int	tag;
	
	tag = [[sender selectedCell] tag];

#ifdef REDOOMED
	[[sideform_i	cellAt:2+tag :0]
		setStringValue:RDE_NSStringFromCString([texturePalette_i  getSelTextureName])];
#else // Original
	[[sideform_i	cellAt:2+tag :0]
		setStringValue:[texturePalette_i  getSelTextureName]];
#endif

	[self	sideChanged:NULL];
	return self;
}

- setTP:sender
{
	int	tag;
	
	tag = [[sender selectedCell] tag];

#ifdef REDOOMED
	[texturePalette_i
	    setSelTexture:
	            (char *)RDE_CStringFromNSString([[sideform_i cellAt:2+tag :0] stringValue])];
#else // Original
	[texturePalette_i	setSelTexture:(char *)[[sideform_i cellAt:2+tag :0] stringValue]];
#endif

	return self;
}

- zeroEntry:sender
{
	int	tag;
	
	tag = [[sender selectedCell] tag];

#ifdef REDOOMED
	[[sideform_i	cellAt:2+tag :0] setStringValue:@"-"];
#else // Original
	[[sideform_i	cellAt:2+tag :0] setStringValue:"-"];
#endif

	[self	sideChanged:NULL];
	return self;
}

//==========================================================
//
// Suggest a new tag value for this map
//
//==========================================================
- suggestTagValue:sender
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
	return self;
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
- popUpCalc:sender
{
	[firstColCalc_i		makeKeyAndOrderFront:NULL];
	return self;
}

- setFCVal:sender
{
	[fc_currentVal_i  setIntValue:[[sideform_i  cellAt:1 :0]  intValue]];
	return self;
}

- incFirstCol:sender
{
	int	val;
	val = [fc_currentVal_i	intValue];
	val += [fc_incDec_i	intValue];
	[fc_currentVal_i	setIntValue:val];
	[[sideform_i cellAt:1 :0]  setIntValue:val];
	[self	sideChanged:NULL];
	return self;
}

- decFirstCol:sender
{
	int	val;
	val = [fc_currentVal_i	intValue];
	val -= [fc_incDec_i	intValue];
	[fc_currentVal_i	setIntValue:val];
	[[sideform_i cellAt:1 :0]  setIntValue:val];
	[self	sideChanged:NULL];
	return self;
}


//============================================================================


/*
==============
=
= updateLineInspector
=
==============
*/

- updateLineInspector
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
	if (bcmp (&baseline, &oldline, sizeof(baseline)) )
	{
		memcpy (&oldline, &baseline, sizeof(oldline));
		[self updateInspector: NO];
	}
	
	[self	updateLineSpecial];
		
	return self;
}

- updateLineSpecial
{
	int	which;
	
	which = [special_i	intValue];
	[lineSpecialPanel_i	setSpecial:which];
	return self;
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

- baseLine: (worldline_t *)line
{
	*line = baseline;
	return self;
}

@end