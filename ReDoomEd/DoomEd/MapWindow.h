// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@interface MapWindow: Window
{
	id		scrollview_i;
	id		mapview_i;
	
#ifdef REDOOMED
	// specify scalemenu_i & gridmenu_i as PopUpList instances
	PopUpList *scalemenu_i;
	id		scalebutton_i;
	PopUpList *gridmenu_i;
	id		gridbutton_i;
#else // Original
	id		scalemenu_i, scalebutton_i;
	id		gridmenu_i, gridbutton_i;	
#endif	
	
	NXPoint	oldscreenorg;			// taken when resizing to keep view constant
	NXPoint	presizeorigin;			// map view origin before resize
}

- initFromEditWorld;
- mapView;

- scalemenu;
- scalebutton;
- gridmenu;
- gridbutton;

- reDisplay: (NXRect *)dirty;

@end
