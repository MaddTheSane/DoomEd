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

- (DETool)currentTool
{
	return [toolmatrix_i selectedRow];
}

- (void)changeTool:(DETool)which
{
	[toolmatrix_i selectCellAtRow:which column:0];
}


@end
