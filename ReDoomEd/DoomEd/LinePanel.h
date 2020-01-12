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
	IBOutlet NSTextField	*p1_i;
	IBOutlet NSTextField	*p2_i;
	IBOutlet NSTextField	*special_i;
	
	IBOutlet NSButton	*pblock_i;
	IBOutlet NSButton	*toppeg_i;
	IBOutlet NSButton	*bottompeg_i;
	IBOutlet NSButton	*twosided_i;
	IBOutlet NSButton	*secret_i;
	IBOutlet NSButton	*soundblock_i;
	IBOutlet NSButton	*dontdraw_i;
	IBOutlet NSButton	*monsterblock_i;
	
	IBOutlet NSMatrix	*sideradio_i;
	IBOutlet NSForm	*sideform_i;
	IBOutlet NSTextField	*tagField_i;
	IBOutlet NSTextField	*linelength_i;
	
	IBOutlet NSPanel	*window_i;
	IBOutlet NSPanel	*firstColCalc_i;
	IBOutlet NSTextField	*fc_currentVal_i;
	IBOutlet NSTextField	*fc_incDec_i;
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
