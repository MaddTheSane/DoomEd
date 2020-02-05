//
// docview of Patch Palette in TextureEdit
//

// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"Coordinator.h"
#import 	"TexturePatchView.h"
#import	"TextureEdit.h"
@implementation TexturePatchView

//==============================================================
//
//	Init the storage for the Patch Palette dividers
//
//==============================================================
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

//==============================================================
//
//	Add a Patch Palette divider (new set of patches)
//
//==============================================================
- addDividerX:(int)x Y:(int)y String:(char *)string;
{
	divider_t		d;
	
	d.x = x;
	d.y = y;
	strcpy (d.string, string );
	[dividers_i	addElement:&d ];
	
	return self;
}

//==============================================================
//
//	Dump all the dividers (for resizing)
//
//==============================================================
- dumpDividers
{
	[dividers_i	empty];
	return self;
}

//==============================================================
//
//	Draw the Patch Palette in the Texture Editor
//
//==============================================================
- drawSelf:(const NXRect *)rects :(int)rectCount
{
	int 		i, max, patchnum,selectedPatch;
	apatch_t	*patch;
	divider_t	*d;
	NXRect	clipview, r;
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'bounds' as an instance var, fake it using a local
	NSRect bounds = [self bounds];
#endif

	selectedPatch = [textureEdit_i	getCurrentPatch];
	patchnum = 0;
	while ((patch = [textureEdit_i	getPatch:patchnum++]) != NULL)
		if (NXIntersectsRect(&patch->r,&rects[0]))
			[patch->image		composite:NX_SOVER toPoint:&patch->r.origin];
	
	clipview = self.frame;
	if (selectedPatch >= 0)
	{
		patch = [textureEdit_i	getPatch:selectedPatch];
		r = patch->r;
		r.origin.x -= 5;
		r.origin.y -= 5;
		r.size.width += 10;
		r.size.height += 10;
		DE_DrawOutline(&r);
		[patch->image		composite:NX_SOVER toPoint:&patch->r.origin];
	}

	//
	//	Draw patch set divider text
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
		PSlineto ( bounds.size.width - SPACING*2, d->y + 12 );

		PSmoveto ( d->x, d->y - 2 );
		PSlineto ( bounds.size.width - SPACING*2, d->y - 2 );
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
	int		patchnum,selectedPatch;
	apatch_t *patch;
	
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'superview' as an instance var, fake it using a local
	NSView *superview = [self superview];

	loc = [theEvent locationInWindow];
	loc = [self convertPoint:loc fromView:nil];
#else // Original
	loc = theEvent->location;
	[self convertPoint:&loc	fromView:NULL];
#endif
	
	selectedPatch = [textureEdit_i	getCurrentPatch];
	patchnum = 0;
	while ((patch = [textureEdit_i	getPatch:patchnum++]) != NULL)
#ifdef REDOOMED
		// Cocoa's mouse:inRect: takes values not pointers
		if ([self	mouse:loc	inRect:patch->r] == YES)
#else // Original
		if ([self	mouse:&loc	inRect:&patch->r] == YES)
#endif
		{
			if (selectedPatch != patchnum -1)
				selectedPatch = patchnum - 1;
			
#ifdef REDOOMED
			if ([theEvent clickCount] == 2)
#else // Original
			if (theEvent->data.mouse.click == 2)
#endif
				[textureEdit_i	addPatch:selectedPatch];
				
			[textureEdit_i	setSelectedPatch:patchnum - 1];
			[superview setNeedsDisplay:YES];
			break;
		}

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

@end
