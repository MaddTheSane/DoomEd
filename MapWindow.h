#import <AppKit/AppKit.h>

@interface MapWindow: NSWindow
{
	IBOutlet NSScrollView		*scrollview_i;
	IBOutlet NSView		*mapview_i;
	
	IBOutlet NSMenu			*scalemenu_i;
	IBOutlet NSButton		*scalebutton_i;
	IBOutlet NSMenu			*gridmenu_i;
	IBOutlet NSButton		*gridbutton_i;
	
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
