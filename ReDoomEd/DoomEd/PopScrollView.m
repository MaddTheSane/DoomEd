// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "PopScrollView.h"

@implementation PopScrollView

/*
====================
=
= initFrame: button:
=
= Initizes a scroll view with a button at it's lower right corner
=
====================
*/

- initFrame:(const NXRect *)frameRect button1:b1 button2:b2
{
	return self = [self initWithFrame:*frameRect button1:button1 button2:button2];
}

- (instancetype)initWithFrame:(NSRect)frameRect button1:(NSButton*)b1 button2:(NSButton*)b2
{
	if (self = [super initWithFrame: frameRect]) {
		[self addSubview: b1];
		[self addSubview: b2];

		button1 = b1;
		button2 = b2;

		[self setHasHorizontalScroller: YES];
		[self setHasVerticalScroller: YES];
	}
			
	return self;
}

/*
================
=
= tile
=
= Adjust the size for the pop up scale menu
=
=================
*/

#ifdef REDOOMED
// Cocoa version
- (void) tile
#else // Original
- tile
#endif
{
	NXRect	scrollerframe;
	NXRect	buttonframe, buttonframe2;
	NXRect	newframe;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'hScroller' as an instance var, fake it using a local
	NSScroller *hScroller = [self horizontalScroller];
#endif
	
	[super tile];
	[button1 getFrame: &buttonframe];
	[button2 getFrame: &buttonframe2];
	[hScroller getFrame: &scrollerframe];

	newframe.origin.y = scrollerframe.origin.y;

#ifdef REDOOMED
	// Bugfix: set up the new button frame's left edge based on the right edge of the
	// horizontal scroller, not the right edge of the scrollview; This fixes misplaced
	// buttons on window managers that put the vertical scrollers on the right side of
	// the scrollview, because the horizontal scroller's right edge may not line up
	// with its enclosing scrollview's right edge (horizontal scroller is shifted over
	// by the width of the vertical scroller)
	newframe.origin.x = NSMaxX(scrollerframe) - buttonframe.size.width;
#else // Original
	newframe.origin.x = frame.size.width - buttonframe.size.width;
#endif

	newframe.size.width = buttonframe.size.width;
	newframe.size.height = scrollerframe.size.height;
	scrollerframe.size.width -= newframe.size.width;

#ifdef REDOOMED
	// Cocoa's setFrame: takes a value, not a pointer
	[button1 setFrame: newframe];
#else // Original
	[button1 setFrame: &newframe];
#endif

	newframe.size.width = buttonframe2.size.width;
	newframe.origin.x -= newframe.size.width;

#ifdef REDOOMED
	// Cocoa's setFrame: takes a value, not a pointer
	[button2 setFrame: newframe];
#else // Original
	[button2 setFrame: &newframe];
#endif
	
	scrollerframe.size.width -= newframe.size.width;

#ifdef REDOOMED
	// Cocoa's setFrame: takes a value, not a pointer
	[hScroller setFrame: scrollerframe];
#else // Original
	[hScroller setFrame: &scrollerframe];
#endif

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}


@end

