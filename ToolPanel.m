#import	"ThingPanel.h"
#import "ToolPanel.h"

id	toolpanel_i;

@implementation ToolPanel

- init
{
	toolpanel_i = self;
	return self;
}

- (IBAction)toolChanged:sender
{
	switch([self	currentTool])
	{
		case THING_TOOL:
			[thingpanel_i	pgmTarget];
		default:
			break;
	}
}

- (tool_t)currentTool
{
	return [toolmatrix_i selectedRow];
}

- (void)changeTool:(int)which
{
	[toolmatrix_i selectCellAtRow:which column:0];
}


@end
