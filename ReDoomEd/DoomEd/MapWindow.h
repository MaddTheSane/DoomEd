// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@class MapView;

@interface MapWindow: Window
{
	IBOutlet id		scrollview_i;
	IBOutlet MapView		*mapview_i;
	
#ifdef REDOOMED
	// specify scalemenu_i & gridmenu_i as PopUpList instances
	IBOutlet PopUpList *scalemenu_i;
	IBOutlet id		scalebutton_i;
	IBOutlet PopUpList *gridmenu_i;
	IBOutlet id		gridbutton_i;
#else // Original
	id		scalemenu_i, scalebutton_i;
	id		gridmenu_i, gridbutton_i;	
#endif	
	
	NXPoint	oldscreenorg;			// taken when resizing to keep view constant
	NXPoint	presizeorigin;			// map view origin before resize
}

- initFromEditWorld;
@property (readonly, assign) MapView* mapView;

- scalemenu;
- scalebutton;
- gridmenu;
- gridbutton;

- reDisplay: (NXRect *)dirty;

@end
