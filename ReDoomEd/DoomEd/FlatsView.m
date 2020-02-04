// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"DoomProject.h"
#import	"SectorEditor.h"
#import "FlatsView.h"

@implementation FlatsView
- initWithFrame:(NSRect)frameRect
{
#ifdef REDOOMED
	// moved call to super's initializer here, before member setup (dividers_i)
	self = [super initWithFrame: frameRect];

	if (!self)
		return nil;
#endif

	dividers_i = [	[ Storage alloc ]
				initCount:		0
				elementSize:	sizeof (divider_t )
				description:	NULL ];
				
#ifndef REDOOMED // Original (Disable for ReDoomEd - moved init call earlier)
	[super	initFrame:frameRect];
#endif

	return self;
}

- (void)addDividerX:(int)x Y:(int)y String:(char *)string;
{
	divider_t		d;
	
	d.x = x;
	d.y = y;
	strcpy (d.string, string );
	[dividers_i	addElement:&d ];
}

- (void)dumpDividers
{
	[dividers_i	empty];
}

- drawSelf:(const NXRect *)rects :(int)rectCount
{
	flat_t	*f;
	NSInteger	max, i, cf;
	NXRect	r;
	divider_t	*d;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'bounds' as an instance var, fake it using a local
	NSRect bounds = [self bounds];
#endif
	
	cf = [sectorEdit_i	currentFlat];
	if (cf >= 0)
	{
		f = [sectorEdit_i	getFlat:cf];
		r = f->r;
		r.origin.x -= 5;
		r.origin.y -= 5;
		r.size.width += 10;
		r.size.height += 10;
		DE_DrawOutline(&r);
	}
	
	max = [sectorEdit_i	countOfFlats];
	for (i = 0; i < max; i++)
	{
		f = [sectorEdit_i	getFlat:i];
		if (NXIntersectsRect(&rects[0],&f->r))
			[f->image	composite:NX_COPY	toPoint:&f->r.origin];
	}

	//
	//	Draw flat set divider text
	//
	PSselectfont("Helvetica-Bold",12);
	PSrotate ( 0 );
	max = [dividers_i	count ];
	for (i = 0; i < max; i++)
	{
		d = [dividers_i	elementAt:i ];
		PSsetgray ( 0 );
		PSmoveto( d->x,d->y );
		PSshow ( d->string );
		PSstroke ();

		PSsetlinewidth(1.0);
		PSsetrgbcolor ( 148,0,0 );
		PSmoveto ( d->x, d->y + 12 );
		PSlineto ( bounds.size.width - SPACING, d->y + 12 );

		PSmoveto ( d->x, d->y - 2 );
		PSlineto ( bounds.size.width - SPACING, d->y - 2 );
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
	NSInteger i,max;
	int oldwindowmask;
	flat_t	*f;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'window' as an instance var, fake it using a local
	NSWindow *window = [self window];
#endif

	oldwindowmask = [window addToEventMask:NX_LMOUSEDRAGGEDMASK];

#ifdef REDOOMED
	loc = [theEvent locationInWindow];
	loc = [self convertPoint: loc fromView: nil];
#else // Original
	loc = theEvent->location;
	[self convertPoint:&loc	fromView:NULL];
#endif
	
	max = [sectorEdit_i	countOfFlats];
	for (i = 0;i < max; i++)
	{
		f = [sectorEdit_i		getFlat:i];
		if (NXPointInRect(&loc,&f->r) == YES)
		{
#ifdef REDOOMED
			if ([theEvent clickCount] == 2)
#else // Original
			if (theEvent->data.mouse.click == 2)
#endif
				[sectorEdit_i	selectFlat:i];
			else
				[sectorEdit_i	setCurrentFlat:i];
				
			break;
		}
	}
	
	[window	setEventMask:oldwindowmask];

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

@end
