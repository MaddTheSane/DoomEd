// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"TexturePalette.h"
#import	"TextureEdit.h"
#import "TexturePalView.h"
#import	"DoomProject.h"

@implementation TexturePalView

//==============================================================
//
//	Init the storage for the Texture Palette dividers
//
//==============================================================
- (id)initWithFrame:(NSRect)frameRect
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

//==============================================================
//
//	Add a Texture Palette divider (new set of textures)
//
//==============================================================
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
	int		count;
	texpal_t	*t;
	NXRect	r;
	int		max, i;
	divider_t	*d;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'bounds' as an instance var, fake it using a local
	NSRect bounds = [self bounds];
#endif
	
	//
	// draw selected texture outline
	//
	if ([texturePalette_i	currentSelection] >= 0)
	{
		t = [texturePalette_i getTexture:[texturePalette_i currentSelection]];
		r = t->r;
		r.origin.x -= SPACING/2;
		r.origin.y -= SPACING/2;
		r.size.width += SPACING;
		r.size.height += SPACING;
		DE_DrawOutline(&r);
	}
	
	//
	// draw textures
	//
	count = 0;
	while ((t = [texturePalette_i	getNewTexture:count++]) != NULL)
		if (NSIntersectsRect(rects[0],t->r) == YES)
			[t->image drawAtPoint:t->r.origin fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1];
	
	//
	//	Draw texture set divider text
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
	NSInteger		i,texcount, which;
	NSEventMask oldwindowmask;
	texpal_t	*t;
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
	
	texcount = [texturePalette_i	countOfTextures];
	for (i = texcount - 1;i >= 0;i--)
	{
		t = [texturePalette_i		getNewTexture:i];
		if (NSPointInRect(loc,t->r) == YES)
		{
			which = [texturePalette_i	selectTextureNamed:t->name ];

#ifdef REDOOMED
			if ([theEvent clickCount] == 2)
#else // Original
			if (theEvent->data.mouse.click == 2)
#endif
			{
				[textureEdit_i	menuTarget:NULL];
				[textureEdit_i	newSelection:which];
				break;
			}
		}
	}

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

@end
