
#import <AppKit/AppKit.h>

typedef NS_ENUM(NSInteger, DETool)
{
	SELECT_TOOL = 0,
	POLY_TOOL,
	LINE_TOOL,
	ZOOMIN_TOOL,
	SLIDE_TOOL,
	GET_TOOL,
	THING_TOOL,
	LAUNCH_TOOL
};

typedef DETool tool_t;

@class ToolPanel;
extern ToolPanel *toolpanel_i;

@interface ToolPanel: NSObject
{
    IBOutlet NSMatrix	*toolmatrix_i;
}

- (IBAction)toolChanged:sender;
@property (readonly) DETool currentTool;
- (void)changeTool:(DETool)which;

@end
