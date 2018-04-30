
#import <appkit/appkit.h>

typedef enum
{
	SELECT_TOOL = 0,
	POLY_TOOL,
	LINE_TOOL,
	ZOOMIN_TOOL,
	SLIDE_TOOL,
	GET_TOOL,
	THING_TOOL,
	LAUNCH_TOOL
} tool_t;

@class ToolPanel;
extern ToolPanel *toolpanel_i;

@interface ToolPanel: NSObject
{
    IBOutlet NSMatrix	*toolmatrix_i;
}

- (IBAction)toolChanged:sender;
- (tool_t)currentTool;
- (void)changeTool:(int)which;

@end
