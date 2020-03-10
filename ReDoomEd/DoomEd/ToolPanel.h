// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

typedef NS_ENUM(NSInteger, ToolPanelTool) {
	ToolSelect = 0,
	ToolPolygon,
	ToolLine,
	ToolZoomIn,
	ToolSlide,
	ToolGet,
	ToolThing,
	ToolLaunch
};

@class ToolPanel;
extern ToolPanel *toolpanel_i;

@interface ToolPanel:NSObject
{
    IBOutlet NSMatrix	*toolmatrix_i;
}

- (IBAction)toolChanged:sender;
- (ToolPanelTool)currentTool;
- (void)changeTool:(int)which;

@end

#ifdef REDOOMED
@interface ToolPanel (RDEUtilities)
- (BOOL) rdePerformToolMatrixKeyEquivalent: (NSEvent *) theEvent;
@end
#endif
