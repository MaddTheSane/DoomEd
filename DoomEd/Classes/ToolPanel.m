#import	"ThingPanel.h"
#import "ToolPanel.h"

ToolPanel *toolpanel_i;

@implementation ToolPanel

- init
{
	if (self = [super init]) {
	toolpanel_i = self;
	}
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
	return (tool_t)[toolmatrix_i selectedRow];
}

- (void)changeTool:(int)which
{
	[toolmatrix_i selectCellAtRow:which column:0];
}


@end
