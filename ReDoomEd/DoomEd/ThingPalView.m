// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "ThingPalView.h"
#import	"ThingPalette.h"
#import	"DoomProject.h"
#import	"ThingPanel.h"

@implementation ThingPalView

- drawSelf:(const NXRect *)rects :(int)rectCount
{
	ThingPaletteIcon	*icon;
	NSInteger			max;
	NSInteger			i;
	NSInteger			ci;
	NXRect	r;
	NXPoint	p;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'bounds' as an instance var, fake it using a local
	NSRect bounds = [self bounds];
#endif
	
	ci = [thingPalette_i currentIcon];
	if (ci >= 0)
	{
		icon = [thingPalette_i	getIcon:ci];
		r = icon.r;
		r.origin.x -= 5;
		r.origin.y -= 5;
		r.size.width += 10;
		r.size.height += 10;
		DE_DrawOutline(&r);
	}
	
	max = [thingPalette_i countOfIcons];
	for (i = 0; i < max; i++)
	{
		icon = [thingPalette_i	getIcon:i];
		if (NSIntersectsRect(rects[0],icon.r) == YES)
		{
			p = icon.r.origin;
			p.x += (ICONSIZE - icon.imageSize.width)/2;
			p.y += (ICONSIZE - icon.imageSize.height)/2;
			[icon.image drawAtPoint:p fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1];
		}
	}

	//
	//	Draw icon divider text
	//
	PSselectfont("Helvetica-Bold",12);
	PSrotate ( 0 );
	for (i = 0; i < max; i++)
	{
		icon = [thingPalette_i	getIcon:i ];
		if (icon.image != NULL)
			continue;
			
		PSsetgray ( 0 );
		PSmoveto( icon.r.origin.x,icon.r.origin.y + ICONSIZE/2);
		PSshow ( icon.name.UTF8String );
		PSstroke ();

		PSsetrgbcolor ( 148,0,0 );
		PSsetlinewidth( 1.0 );
		PSmoveto ( icon.r.origin.x, icon.r.origin.y + ICONSIZE/2 + 12 );
		PSlineto ( bounds.size.width - SPACING,
				icon.r.origin.y + ICONSIZE/2 + 12 );

		PSmoveto ( icon.r.origin.x, icon.r.origin.y + ICONSIZE/2 - 2 );
		PSlineto ( bounds.size.width - SPACING,
				icon.r.origin.y + ICONSIZE/2 - 2 );
		PSstroke ();
	}
	
	return self;
}

#ifdef REDOOMED
// Cocoa version
- (void) mouseDown:(NSEvent *)theEvent
#else // Original
- mouseDown:(NXEvent *)theEvent
#endif
{
	NXPoint	loc;
	NSInteger		i;
	NSInteger		max;
	NSEventMask		oldwindowmask;
	ThingPaletteIcon	*icon;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'window' as an instance var, fake it using a local
	NSWindow *window = [self window];
#endif

	oldwindowmask = [window addToEventMask:NSEventMaskLeftMouseDragged];

#ifdef REDOOMED
	loc = [theEvent locationInWindow];
	loc = [self convertPoint:loc fromView:nil];
#else // Original
	loc = theEvent->location;
	[self convertPoint:&loc	fromView:NULL];
#endif
	
	max = [thingPalette_i	countOfIcons];
	for (i = 0;i < max; i++)
	{
		icon = [thingPalette_i		getIcon:i];
		if (NSPointInRect(loc,icon.r) == YES)
		{
			[thingPalette_i	setCurrentIcon:i];
			[thingpanel_i	selectThingWithIcon:icon.name];
			break;
		}
	}
	
	[window	setEventMask:oldwindowmask];

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

@end
