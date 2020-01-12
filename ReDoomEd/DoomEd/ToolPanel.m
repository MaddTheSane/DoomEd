// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"ThingPanel.h"
#import "ToolPanel.h"

id	toolpanel_i;

@implementation ToolPanel

- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	toolpanel_i = self;
	return self;
}

- toolChanged:sender
{
	switch([self	currentTool])
	{
		case THING_TOOL:
			[thingpanel_i	pgmTarget];
		default:
			break;
	}
    return self;
}

- (tool_t)currentTool
{
	return [toolmatrix_i selectedRow];
}

- changeTool:(int)which
{
	[toolmatrix_i	selectCellAt:which :0];
	return self;
}


@end

#ifdef REDOOMED
@implementation ToolPanel (RDEUtilities)

// rdePerformToolMatrixKeyEquivalent: RDE utility method to manually forward a hotkey event
// to the tool button matrix - allows the user to select tools using hotkeys when the tool
// panel isn't the key window (called from MapView's keyDown:)

- (BOOL) rdePerformToolMatrixKeyEquivalent: (NSEvent *) theEvent
{
    return [toolmatrix_i performKeyEquivalent: theEvent];
}

@end
#endif
