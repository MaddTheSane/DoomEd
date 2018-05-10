
#import "ThingPalView.h"
#import	"ThingPalette.h"
#import	"DoomProject.h"
#import	"ThingPanel.h"

@implementation ThingPalView

- (void)drawRect:(NSRect)dirtyRect
{
	icon_t	*icon;
	int		max;
	int		i;
	int		ci;
	NSRect	r;
	NSPoint	p;
	
	ci = [thingPalette_i	currentIcon];
	if (ci >= 0)
	{
		icon = [thingPalette_i	getIcon:ci];
		r = icon->r;
		r.origin.x -= 5;
		r.origin.y -= 5;
		r.size.width += 10;
		r.size.height += 10;
		DE_DrawOutline(r);
	}
	
	max = [thingPalette_i	getNumIcons];
	for (i = 0; i < max; i++)
	{
		icon = [thingPalette_i	getIcon:i];
		if (NSIntersectsRect(dirtyRect, icon->r))
		{
			p = icon->r.origin;
			p.x += (ICONSIZE - icon->imagesize.width)/2;
			p.y += (ICONSIZE - icon->imagesize.height)/2;
			[icon->image drawAtPoint:p fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
		}
	}

	//
	//	Draw icon divider text
	//
	[[NSFont fontWithName:@"Helvetica-Bold" size:12] set];
	//PSselectfont("Helvetica-Bold",12);
	//PSrotate ( 0 );
	for (i = 0; i < max; i++)
	{
		icon = [thingPalette_i	getIcon:i ];
		if (icon->image != NULL)
			continue;
		
		[[NSColor blackColor] set];
		[@(icon->name) drawAtPoint:NSMakePoint(icon->r.origin.x, icon->r.origin.y + ICONSIZE/2) withAttributes:nil];

		[[NSColor colorWithCalibratedRed:148.0/255 green:0 blue:0 alpha:1] set];
		NSBezierPath *path = [NSBezierPath bezierPath];
		path.lineWidth = 1;
		[path moveToPoint:NSMakePoint( icon->r.origin.x, icon->r.origin.y + ICONSIZE/2 + 12 )];
		[path lineToPoint:NSMakePoint( [self bounds].size.width - SPACING,
									  icon->r.origin.y + ICONSIZE/2 + 12 )];

		[path moveToPoint:NSMakePoint( icon->r.origin.x, icon->r.origin.y + ICONSIZE/2 - 2 )];
		[path lineToPoint:NSMakePoint( [self bounds].size.width - SPACING,
									  icon->r.origin.y + ICONSIZE/2 - 2 )];
		[path stroke];
	}
}

- (void) mouseDown:(NSEvent *)theEvent
{
	NSPoint	loc;
	int		i;
	int		max;
	int		oldwindowmask;
	icon_t	*icon;

	// TODO: Needed?
	//oldwindowmask = [[self window] addToEventMask:NX_LMOUSEDRAGGEDMASK];
	loc = [theEvent locationInWindow];
	loc = [self convertPoint:loc	fromView:NULL];

	max = [thingPalette_i	getNumIcons];
	for (i = 0;i < max; i++)
	{
		icon = [thingPalette_i		getIcon:i];
		if (NSPointInRect(loc, icon->r) == YES)
		{
			[thingPalette_i	setCurrentIcon:i];
			[thingpanel_i	selectThingWithIcon:icon->name];
			break;
		}
	}

	//[[self window] setEventMask:oldwindowmask];
}

@end
