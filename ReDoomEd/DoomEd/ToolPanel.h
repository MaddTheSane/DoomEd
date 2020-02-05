// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

typedef NS_ENUM(NSInteger, tool_t)
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

@class ToolPanel;
extern ToolPanel *toolpanel_i;

@interface ToolPanel:NSObject
{
    IBOutlet NSMatrix	*toolmatrix_i;
}

- (IBAction)toolChanged:sender;
- (tool_t)currentTool;
- changeTool:(int)which;

@end

#ifdef REDOOMED
@interface ToolPanel (RDEUtilities)
- (BOOL) rdePerformToolMatrixKeyEquivalent: (NSEvent *) theEvent;
@end
#endif
