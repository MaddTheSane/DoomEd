#import "ps_quartz.h"

//
// docview of Patch Palette in TextureEdit
//
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
	if (self = [super initWithFrame:frameRect]) {
		dividers_i = [[CompatibleStorage alloc]
					  initCount: 0
					  elementSize: sizeof (divider_t )
					  description: NULL];
	}
	
	return self;
}

//==============================================================
//
//	Add a Patch Palette divider (new set of patches)
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

//==============================================================
//
//	Dump all the dividers (for resizing)
//
//==============================================================
- (void)dumpDividers
{
	[dividers_i	empty];
}

//==============================================================
//
//	Draw the Patch Palette in the Texture Editor
//
//==============================================================
- drawSelf:(const NSRect *)rects :(int)rectCount
{
	int 		i, max, patchnum,selectedPatch;
	apatch_t	*patch;
	divider_t	*d;
	NSRect	clipview, r;

	selectedPatch = [textureEdit_i	getCurrentPatch];
	patchnum = 0;
	while ((patch = [textureEdit_i	getPatch:patchnum++]) != NULL)
		if (NSIntersectsRect(patch->r, rects[0]))
			[patch->image drawAtPoint:patch->r.origin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
	
	clipview = [self frame];
	if (selectedPatch >= 0)
	{
		patch = [textureEdit_i	getPatch:selectedPatch];
		r = patch->r;
		r.origin.x -= 5;
		r.origin.y -= 5;
		r.size.width += 10;
		r.size.height += 10;
		DE_DrawOutline(&r);
		[patch->image drawAtPoint:patch->r.origin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
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
		PSlineto ( [self bounds].size.width - SPACING*2, d->y + 12 );

		PSmoveto ( d->x, d->y - 2 );
		PSlineto ( [self bounds].size.width - SPACING*2, d->y - 2 );
		PSstroke ();
	}
	
	return self;
}

- (void) mouseDown:(NSEvent *)theEvent
{
	NSPoint	loc;
	int		patchnum,selectedPatch;
	apatch_t *patch;
	
	loc = [theEvent locationInWindow];
	[self convertPoint:loc	fromView:NULL];
	
	selectedPatch = [textureEdit_i	getCurrentPatch];
	patchnum = 0;
	while ((patch = [textureEdit_i	getPatch:patchnum++]) != NULL)
	{
		if ([self	mouse:loc	inRect:patch->r] == YES)
		{
			if (selectedPatch != patchnum -1)
				selectedPatch = patchnum - 1;

			if ([theEvent clickCount] == 2)
				[textureEdit_i	addPatch:selectedPatch];

			[textureEdit_i	setSelectedPatch:patchnum - 1];
			[[self superview] setNeedsDisplay:YES];
			break;
		}
	}
}

@end
