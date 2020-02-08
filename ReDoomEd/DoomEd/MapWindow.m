// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "MapWindow.h"
#import "MapView.h"
#import "PopScrollView.h"
#import "EditWorld.h"

NXSize	minsize = {256, 256};
NXSize	newsize = {400, 400};

static	int	cornerx = 128, cornery = 64;

#ifdef REDOOMED
#   if RDE_SDK_REQUIRES_PROTOCOL_FOR_WINDOW_DELEGATES
@interface MapWindow (NSWindowDelegateProtocol) <NSWindowDelegate>
@end
#   endif
#endif

@implementation MapWindow

- (void)dealloc
{
	
	[super dealloc];
}


- initFromEditWorld
{
	id		oldobj_i;
	NXSize	screensize;
	NXRect	wframe;
	NXPoint	origin;
	NXRect	mapbounds;

//
// set up the window
//		
	[NXApp getScreenSize: &screensize];
	if (cornerx + newsize.width > screensize.width - 70)
		cornerx = 128;
	if (cornery + newsize.height > screensize.height - 70)
		cornery = 64;
	wframe.origin.x = cornerx;
	wframe.origin.y = screensize.height - newsize.height - cornery;
	wframe.size = newsize;

#if 0
	cornerx += 32;
	cornery += 32;
#endif

#ifdef REDOOMED
	self =
#endif
	[self initWithContentRect: wframe
					styleMask: NSResizableWindowMask | NSTitledWindowMask| NSClosableWindowMask | NSMiniaturizableWindowMask
					  backing: NSBackingStoreBuffered
						defer: NO];
	
#ifdef REDOOMED
	if (!self)
		return nil;

	// Cocoa's setMinSize: takes a value, not a pointer
	[self	setMinSize:	minsize];
#else // Original
	[self	setMinSize:	&minsize];
#endif

// initialize the map view 
	mapview_i = [[MapView alloc] initFromEditWorld];
	[scrollview_i setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	
//		
// initialize the pop up menus
//
	scalemenu_i = [[PopUpList alloc] init];
	[scalemenu_i setTarget: mapview_i];
	[scalemenu_i setAction: @selector(scaleMenuTarget:)];

	[scalemenu_i addItemWithTitle: @"3.125%"];
	[scalemenu_i addItemWithTitle: @"6.25%"];
	[scalemenu_i addItemWithTitle: @"12.5%"];
	[scalemenu_i addItemWithTitle: @"25%"];
	[scalemenu_i addItemWithTitle: @"50%"];
	[scalemenu_i addItemWithTitle: @"100%"];
	[scalemenu_i addItemWithTitle: @"200%"];
	[scalemenu_i addItemWithTitle: @"400%"];
	[scalemenu_i selectCellAt: 5 : 0];
	
	scalebutton_i = NXCreatePopUpListButton(scalemenu_i);


	gridmenu_i = [[PopUpList alloc] init];
	[gridmenu_i setTarget: mapview_i];
	[gridmenu_i setAction: @selector(gridMenuTarget:)];

	[gridmenu_i addItemWithTitle: @"grid 1"];
	[gridmenu_i addItemWithTitle: @"grid 2"];
	[gridmenu_i addItemWithTitle: @"grid 4"];
	[gridmenu_i addItemWithTitle: @"grid 8"];
	[gridmenu_i addItemWithTitle: @"grid 16"];
	[gridmenu_i addItemWithTitle: @"grid 32"];
	[gridmenu_i addItemWithTitle: @"grid 64"];
	
	[gridmenu_i selectCellAt: 3 : 0];
	
	gridbutton_i = NXCreatePopUpListButton(gridmenu_i);

// initialize the scroll view
	wframe.origin.x = wframe.origin.y = 0;
	scrollview_i = [[PopScrollView alloc] 
		initWithFrame: 	wframe 
		button1: 		scalebutton_i
		button2:		gridbutton_i
	];
	[scrollview_i setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	
// link objects together
	[self setDelegate: self];
	
	oldobj_i = nil;
	[scrollview_i setDocumentView: mapview_i];
	if (oldobj_i)
		[oldobj_i release];

#ifdef REDOOMED
	// Cocoa compatibility: -[NSWindow setContentView:] doesn't return a value
	[self setContentView: scrollview_i];
#else // Original
	oldobj_i = [self  setContentView: scrollview_i];
	if (oldobj_i)
		[oldobj_i free];
#endif
	
// scroll to the middle
	[editworld_i getBounds: &mapbounds];
	origin.x = mapbounds.origin.x + mapbounds.size.width / 2 - newsize.width /2;
	origin.y = mapbounds.origin.y + mapbounds.size.height / 2 - newsize.width /2;
	[mapview_i setOrigin: &origin scale:1];

	return self;
}

@synthesize mapView=mapview_i;
@synthesize scalemenu=scalemenu_i;

- scalebutton
{
	return scalebutton_i;
}

@synthesize gridmenu=gridmenu_i;

- gridbutton
{
	return gridbutton_i;
}


- reDisplay: (NXRect *)dirty
{
	[mapview_i displayDirty: dirty];
	return self;
}

/*
=============================================================================

					DELEGATE METHODS

=============================================================================
*/


#ifdef REDOOMED
// editworld_i is no longer the MapWindow delegate (the MapWindow instance is now its
// own delegate), so manually forward windowWillClose messages; note that EditWorld's
// implementation of windowWillClose: expects to receive a window object, not a
// notification
- (void) windowWillClose: (NSNotification *) notification
{
	[editworld_i windowWillClose: [notification object]];
}
#endif


/*
=================
=
= windowWillResize: toSize:
=
= note the origin of the window on the screen so that windowDidResize can change the
= MapView origin if the origin corner of the window is moved.
=
= This will be called continuosly during resizing, even though it only needs to be called once.
=
==================
*/

#ifdef REDOOMED
// Cocoa version
- (NSSize) windowWillResize: (NSWindow *) sender toSize: (NSSize) frameSize
#else // Original
- windowWillResize:sender toSize:(NXSize *)frameSize
#endif
{
	oldscreenorg.x = oldscreenorg.y = 0;

#ifdef REDOOMED
	// Cocoa's convertBaseToScreen: takes a value, not a pointer, and returns the converted point
	oldscreenorg = [self convertPointToScreen: oldscreenorg];
#else // Original
	[self convertBaseToScreen: &oldscreenorg];
#endif

	[mapview_i getCurrentOrigin: &presizeorigin];

#ifdef REDOOMED
	// Cocoa version returns the frame size, not self
	return frameSize;
#else // Original
	return self;
#endif
}

/*
======================
=
= windowDidResize:
=
= expand / shrink bounds
= When this is called all the views have allready been resized and possible scrolled (sigh)
=
======================
*/

#ifdef REDOOMED
// Cocoa version
- (void) windowDidResize: (NSNotification *) notification
#else // Original
- windowDidResize:sender
#endif
{
#ifndef REDOOMED // Original (Disable for ReDoomEd - the code using these vars was disabled below)
	NXRect	wincont, scrollcont;
#endif
	float		scale;
	NXPoint	newscreenorg;

//
// change frame if needed
//	
	newscreenorg.x = newscreenorg.y = 0;

#ifdef REDOOMED
	// Cocoa's convertBaseToScreen: takes a value, not a pointer, and returns the converted point
	newscreenorg = [self convertPointToScreen: newscreenorg];
#else // Original
	[self convertBaseToScreen: &newscreenorg];
#endif

	scale = [mapview_i currentScale];
	presizeorigin.x += (newscreenorg.x - oldscreenorg.x)/scale;
	presizeorigin.y += (newscreenorg.y - oldscreenorg.y)/scale;
	[mapview_i setOrigin: &presizeorigin];

#ifndef REDOOMED // Original (Disable for ReDoomEd - unnecessary calls with no side-effects)
//
// resize drag image
//
	[Window
		getContentRect:	&wincont 
		forFrameRect:		&frame
		style:			NX_RESIZEBARSTYLE
	];

	[ScrollView
		getContentSize:	&scrollcont.size
		forFrameSize:		&wincont.size
		horizScroller:		YES
		vertScroller:		YES
		borderType:		NX_NOBORDER
	];
#endif

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}


@end
