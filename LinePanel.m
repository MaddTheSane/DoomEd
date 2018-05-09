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

- (id)init
{
	if (self = [super init]) {
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

	lineSpecialPanel_i = [[SpecialList alloc] init];
	[lineSpecialPanel_i setSpecialTitle:@"Line Inspector - Specials"];
	[lineSpecialPanel_i setFrameName:@"LineSpecialPanel"];
	[lineSpecialPanel_i setDelegate:self];
	}
	
	return self;
}

- (void)emptySpecialList
{
	[lineSpecialPanel_i	empty];
}

- (void)saveFrame
{
	[lineSpecialPanel_i	saveFrame];
	if (firstColCalc_i)
		[firstColCalc_i		saveFrameUsingName:@"FirstColCalc"];
	if (window_i)
		[window_i	saveFrameUsingName:@"LineInspector"];
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

- (IBAction)activateSpecialList:(id)sender
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

- (IBAction)menuTarget:(id)sender
{
	if (!window_i)
	{
		[NSBundle loadNibNamed: @"line"
						 owner: self];
		[window_i	setFrameUsingName:@"LineInspector"];
		[firstColCalc_i		setFrameUsingName:@"FirstColCalc"];
	}

	[window_i orderFront:self];
}

/*
==============
=
= sideRadioTarget:
=
==============
*/

- (IBAction)sideRadioTarget:(id)sender
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

- (void)getSide: (worldside_t *)side
{
	side->flags = [[sideform_i cellAtIndex:0] intValue];
	side->firstcollumn = [[sideform_i cellAtIndex:1] intValue];
	strncpy (side->toptexture, [[sideform_i cellAtIndex:2] stringValue].UTF8String, 9);
	strncpy (side->midtexture, [[sideform_i cellAtIndex:3] stringValue].UTF8String, 9);
	strncpy (side->bottomtexture, [[sideform_i cellAtIndex:4] stringValue].UTF8String, 9);
	memset (&side->ends,0,sizeof(side->ends));
}

/*
==================
=
= setSide:
=
= Sets fields in a form object based on a mapside structure
==================
*/

- (void)setSide: (worldside_t *)side
{
	[[sideform_i cellAtIndex:0] setIntValue:side->flags];
	[[sideform_i cellAtIndex:1] setIntValue:side->firstcollumn];
	[[sideform_i cellAtIndex:2] setStringValue:@(side->toptexture)];
	[[sideform_i cellAtIndex:3] setStringValue:@(side->midtexture)];
	[[sideform_i cellAtIndex:4] setStringValue:@(side->bottomtexture)];
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

	[window_i enableFlushWindow];
	[window_i flushWindow];
}

//============================================================================


- (void)changeLineFlag: (DELineFlag)mask to: (DELineFlag)set
{
	int	i;
	worldline_t	*line;
	
	for (i=0 ; i<numlines ; i++)
		if (lines[i].selected > 0)
		{
			line = &lines[i];
			line->flags &= mask;
			line->flags |= set;
			[editworld_i changeLine: i to: line];
		}
		
	[editworld_i updateWindows];
}

- (IBAction)monsterblockChanged:(id)sender
{
	NSInteger	state;
	state = [monsterblock_i state];	
	[self changeLineFlag: ~DELineMonsterBlock  to: (DELineMonsterBlock*state)];
}

- (IBAction)blockChanged:(id)sender
{
	NSInteger	state;
	state = [pblock_i state];	
	[self changeLineFlag: ~ML_BLOCKMOVE  to: (DELineFlag)(ML_BLOCKMOVE*state)];
}

- (IBAction)secretChanged:(id)sender
{
	NSInteger	state;
	state = [secret_i	state];
	[self	changeLineFlag: ~DELineSecret to:(DELineSecret*state)];
}

- (IBAction)dontDrawChanged:(id)sender
{
	NSInteger	state;
	state = [dontdraw_i	state];
	[self	changeLineFlag: ~DELineDontDraw	to:(DELineDontDraw*state)];
}

- (IBAction)soundBlkChanged:(id)sender
{
	NSInteger	state;
	state = [soundblock_i	state];
	[self	changeLineFlag: ~DELineSoundBlock	to:(DELineSoundBlock*state)];
}

- (IBAction)twosideChanged:(id)sender
{
	NSInteger	state;
	state = [twosided_i state];	
	[self changeLineFlag: ~DELineTwoSided  to: (DELineTwoSided*state)];
}

- (IBAction)toppegChanged: sender
{
	NSInteger	state;
	state = [toppeg_i state];	
	[self changeLineFlag: ~DELineDontPegTop  to: (DELineDontPegTop*state)];
}

- (IBAction)bottompegChanged:(id)sender
{
	NSInteger	state;
	state = [bottompeg_i state];	
	[self changeLineFlag: ~DELineDontPegBottom  to: (DELineDontPegBottom*state)];
}

- (IBAction)specialChanged:(id)sender
{
	int		i,value;
	
	value = [special_i intValue];	
	for (i=0 ; i<numlines ; i++)
		if (lines[i].selected > 0)
		{
			lines[i].special = value;
			[editworld_i changeLine: i to: &lines[i]];
		}
	
	[lineSpecialPanel_i	setSpecial:[special_i	intValue]];
	[editworld_i updateWindows];
}


- (IBAction)tagChanged:(id)sender
{
	int		i,value;
	
	value = [tagField_i intValue];	
	for (i=0 ; i<numlines ; i++)
		if (lines[i].selected > 0)
		{
			lines[i].tag = value;
			[editworld_i changeLine: i to: &lines[i]];
		}
	
	[editworld_i updateWindows];
}


- (IBAction)sideChanged:(id)sender
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

- (IBAction)getFromTP:(id)sender
{
	NSInteger	tag;
	
	tag = [[sender selectedCell] tag];
	[[sideform_i	cellAtRow:2+tag column:0]
		setStringValue:@([texturePalette_i getSelTextureName])];
	[self	sideChanged:NULL];
}

- (IBAction)setTP:(id)sender
{
	NSInteger	tag;
	
	tag = [[sender selectedCell] tag];
	[texturePalette_i	setSelTexture:[[sideform_i cellAtRow:2+tag column:0] stringValue].UTF8String];
}

- (IBAction)zeroEntry:(id)sender
{
	NSInteger	tag;
	
	tag = [[sender selectedCell] tag];
	[[sideform_i	cellAtRow:2+tag column:0] setStringValue:@"-"];
	[self	sideChanged:NULL];
}

//==========================================================
//
// Suggest a new tag value for this map
//
//==========================================================
- (IBAction)suggestTagValue:(id)sender
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
- (IBAction)popUpCalc:(id)sender
{
	[firstColCalc_i		makeKeyAndOrderFront:NULL];
}

- (IBAction)setFCVal:(id)sender
{
	[fc_currentVal_i  setIntValue:[[sideform_i  cellAtRow:1 column:0]  intValue]];
}

- (IBAction)incFirstCol:(id)sender
{
	int	val;
	val = [fc_currentVal_i	intValue];
	val += [fc_incDec_i	intValue];
	[fc_currentVal_i	setIntValue:val];
	[[sideform_i cellAtRow:1 column:0]  setIntValue:val];
	[self	sideChanged:NULL];
}

- (IBAction)decFirstCol:(id)sender
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
	if (bcmp (&baseline, &oldline, sizeof(baseline)) )
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

- (void)windowDidUpdate:(NSNotification *)notification
{
	[self updateInspector: YES];
}


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
