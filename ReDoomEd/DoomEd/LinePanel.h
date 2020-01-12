// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

#import "EditWorld.h"

@class LinePanel;

extern	LinePanel *linepanel_i;
extern	id	lineSpecialPanel_i;

@interface LinePanel:Object
{
	id	p1_i;
	id	p2_i;
	id	special_i;
	
	id	pblock_i;
	id	toppeg_i;
	id	bottompeg_i;
	id	twosided_i;
	id	secret_i;
	id	soundblock_i;
	id	dontdraw_i;
	id	monsterblock_i;
	
	id	sideradio_i;
	NSForm	*sideform_i;
	id	tagField_i;
	id	linelength_i;
	
	id	window_i;
	id	firstColCalc_i;
	id	fc_currentVal_i;
	id	fc_incDec_i;
	worldline_t	baseline, oldline;
}

- emptySpecialList;
- (IBAction)menuTarget:sender;
- updateInspector: (BOOL)force;
- (IBAction)sideRadioTarget:sender;
- (void)updateLineInspector;

- (IBAction)monsterblockChanged:sender;
- (IBAction)blockChanged: sender;
- (IBAction)twosideChanged: sender;
- (IBAction)toppegChanged: sender;
- (IBAction)bottompegChanged: sender;
- (IBAction)secretChanged:sender;
- (IBAction)soundBlkChanged:sender;
- (IBAction)dontDrawChanged:sender;
- (IBAction)specialChanged: sender;
- (IBAction)tagChanged: sender;
- (IBAction)sideChanged: sender;

- (IBAction)getFromTP:sender;
- (IBAction)setTP:sender;
- (IBAction)zeroEntry:sender;
- (IBAction)suggestTagValue:sender;
- (int)getTagValue;

// FIRSTCOL CALCULATOR
- (IBAction)setFCVal:sender;
- (IBAction)popUpCalc:sender;
- (IBAction)incFirstCol:sender;
- (IBAction)decFirstCol:sender;

-baseLine: (worldline_t *)line;

- (void)updateLineSpecial;
- (IBAction)activateSpecialList:sender;
- updateLineSpecialsDSP:(FILE *)stream;
@end
