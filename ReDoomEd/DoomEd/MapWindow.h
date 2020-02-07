// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@class MapView;

@interface MapWindow: NSWindow
{
	IBOutlet NSScrollView	*scrollview_i;
	IBOutlet MapView		*mapview_i;
	
#ifdef REDOOMED
	// specify scalemenu_i & gridmenu_i as PopUpList instances
	IBOutlet PopUpList *scalemenu_i;
	IBOutlet NSButton *scalebutton_i;
	IBOutlet PopUpList *gridmenu_i;
	IBOutlet NSButton *gridbutton_i;
#else // Original
	id		scalemenu_i, scalebutton_i;
	id		gridmenu_i, gridbutton_i;	
#endif	
	
	NXPoint	oldscreenorg;			// taken when resizing to keep view constant
	NXPoint	presizeorigin;			// map view origin before resize
}

- (instancetype)initFromEditWorld;
@property (readonly, assign) MapView* mapView;

@property (readonly, assign) PopUpList *scalemenu;
- (NSButton *)scalebutton;
@property (readonly, assign) PopUpList *gridmenu;
- (NSButton *)gridbutton;

- reDisplay: (NXRect *)dirty;

@end
