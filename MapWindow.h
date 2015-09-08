#import <appkit/appkit.h>

@interface MapWindow: NSWindow
{
	IBOutlet id		scrollview_i;
	IBOutlet id		mapview_i;
	
	IBOutlet id		scalemenu_i, scalebutton_i;
	IBOutlet id		gridmenu_i, gridbutton_i;	
	
	NSPoint	oldscreenorg;			// taken when resizing to keep view constant
	NSPoint	presizeorigin;			// map view origin before resize
}

- (instancetype)initFromEditWorld;
- (void)mapView;

- (void)scalemenu;
- (void)scalebutton;
- (void)gridmenu;
- (void)gridbutton;

- (void)reDisplay: (NSRect *)dirty;

@end
