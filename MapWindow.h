#import <AppKit/AppKit.h>

@class MapView;

@interface MapWindow: NSWindow <NSWindowDelegate>
{
	IBOutlet NSScrollView	*scrollview_i;
	IBOutlet MapView		*mapview_i;
	
	IBOutlet NSMenu			*scalemenu_i;
	IBOutlet NSPopUpButton	*scalebutton_i;
	IBOutlet NSMenu			*gridmenu_i;
	IBOutlet NSPopUpButton	*gridbutton_i;
	
	NSPoint	oldscreenorg;			// taken when resizing to keep view constant
	NSPoint	presizeorigin;			// map view origin before resize
}

- (instancetype)initFromEditWorld;
@property (assign) NSView *mapView;

@property (assign) NSMenu *scalemenu;
@property (assign) NSButton *scalebutton;
@property (assign) NSMenu *gridmenu;
@property (assign) NSButton *gridbutton;

- (void)reDisplay: (NSRect *)dirty;

@end
