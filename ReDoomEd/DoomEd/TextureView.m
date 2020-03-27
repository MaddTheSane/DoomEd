//
// This belongs to TextureEdit (docView of TextureEdit's ScrollView)
//

// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "TextureEdit.h"
#import "EditWorld.h"
#import "TextureView.h"
//#import "wadfiles.h"


@implementation TextureView

- (BOOL) acceptsFirstResponder
{
	return YES;
}

- initWithFrame:(NSRect)frameRect
{
#ifdef REDOOMED
	self =
#endif
	[super initWithFrame:frameRect];

#ifdef REDOOMED
	if (!self)
		return nil;
#endif

	deltaTable = [[ Storage	alloc ]
					initCount:0
					elementSize:sizeof(delta_t)
					description:NULL];

	return self;
}

#ifdef REDOOMED
// Cocoa version
- (void) keyDown:(NSEvent *)theEvent
#else // Original
- keyDown:(NXEvent *)theEvent
#endif
{
#ifdef REDOOMED
	// Cocoa compatibility
	switch([[theEvent characters] characterAtIndex: 0])
#else // Original
	switch(theEvent->data.key.charCode)
#endif
	{
		case 0x7f:	// delete patch
			[textureEdit_i	deleteCurrentPatch:NULL];
			break;
		case 0x6c:	// toggle lock
			[textureEdit_i	doLockToggle];
			break;
		case 0xac:
		case 0xaf:	// sort down
			[textureEdit_i	sortDown:NULL];
			break;
		case 0xad:
		case 0xae:	// sort up
			[textureEdit_i	sortUp:NULL];
			break;
		case 0xd:
			[textureEdit_i	finishTexture:NULL];
			break;
		#if 0
		default:
			printf("charCode:%x\n",theEvent->data.key.charCode);
			break;
		#endif
	}

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

- drawSelf:(const NXRect *)rects :(int)rectCount
{
	int		ct,outlineflag;
	NSInteger	patchCount, i;
	texpatch_t	*tpatch;
	
	ct = [textureEdit_i	currentTexture];
	if (ct < 0)
		return self;
		
	NXSetColor(NXConvertRGBToColor(1,0,0));
	NXRectFill(&rects[0]);
	
	outlineflag = [textureEdit_i	getOutlineFlag];
	PSsetgray(NX_DKGRAY);

	//
	// draw all patches
	//
	patchCount = [texturePatches	count];
	for (i = 0;i < patchCount; i++)
	{
		tpatch = [texturePatches	elementAt:i];
//		if (NSIntersectsRect(tpatch->r,rects[0]) == YES)
			[tpatch->patch->image_x2 drawAtPoint:tpatch->r.origin fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1];
	}

	//
	// overlay outlines
	//
	if (outlineflag)
		for (i = patchCount - 1;i >= 0;i--)
		{
			tpatch = [texturePatches	elementAt:i];
//			if (NSIntersectsRect(tpatch->r,rects[0]) == YES)
				NXFrameRectWithWidth(&tpatch->r,5);
		}

	//
	// if multiple selections, draw their outlines
	//
	if ([[textureEdit_i selectedTexturePatches] count])
	{
		NSInteger	max;
		
		max = [[textureEdit_i selectedTexturePatches] count];
		for (i = 0;i<max;i++)
		{
			tpatch = [texturePatches	elementAt:*(int *)[[textureEdit_i selectedTexturePatches] elementAt:i]];
			PSsetgray(NX_WHITE);
			NXFrameRectWithWidth(&tpatch->r,5);
		}
	}
	
	return self;
}

#ifdef REDOOMED
// Cocoa version
- (void) rightMouseDown:(NSEvent *)theEvent
#else // Original
- rightMouseDown:(NXEvent *)theEvent
#endif
{
	[[textureEdit_i	selectedTexturePatches]	empty];
	[self setNeedsDisplay:YES];

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

#ifdef REDOOMED
// Cocoa version
- (void) mouseDown:(NSEvent *)theEvent
#else // Original
- mouseDown:(NXEvent *)theEvent
#endif
{
	NXPoint	loc,newloc;
	NSInteger	i,patchcount,ct,max,j,warn,clicked;
	NSEventMask oldwindowmask;
	texpatch_t	*patch;
	NXEvent	*event;
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

	ct = [textureEdit_i	currentTexture];

	//
	// see if a patch was clicked on...
	//
	patchcount = [texturePatches	count];
	clicked = 0;		// no patch clicked on yet...
	for (i = patchcount - 1;i >= 0;i--)
	{
		patch = [texturePatches	elementAt:i];
		if (NSPointInRect(loc,patch->r) == YES)
		{
			//
			// shift-click adds the patch to the select list
			//
#ifdef REDOOMED
			if ([theEvent modifierFlags] & NSEventModifierFlagShift)
#else // Original
			if (theEvent->flags & NX_SHIFTMASK)
#endif
			{
				if ([textureEdit_i	selTextureEditPatchExists:i] == NO)
					[textureEdit_i	addSelectedTexturePatch:i];
				else
					[textureEdit_i	removeSelTextureEditPatch:i];
				[textureEdit_i	updateTexPatchInfo];
			}
			else
			if (![textureEdit_i	selTextureEditPatchExists:i])
			{
				[[textureEdit_i	selectedTexturePatches]	empty];
				[textureEdit_i	addSelectedTexturePatch:i];
				[textureEdit_i	updateTexPatchInfo];
			}
			[self setNeedsDisplay:YES];
			clicked = 1;
			break;
		}
	}
	
	//
	// Did user click outside area? If so, get rid of all selections
	//
	if (!clicked)
		[[textureEdit_i	selectedTexturePatches]	empty];
	
	//
	// move around texture patches
	//
	max = [[textureEdit_i selectedTexturePatches]	count];
	[deltaTable	empty];
	for (j = 0; j < max; j++)
	{
		delta_t	d;
		d.p = [texturePatches	elementAt:
				*(int *)[[textureEdit_i selectedTexturePatches] elementAt:j]];
		d.xoff = loc.x - d.p->r.origin.x;
		d.yoff = loc.y - d.p->r.origin.y;
		[deltaTable	addElement:&d];
	}
	
	do
	{
		event = [NXApp getNextEvent: NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged];

#ifdef REDOOMED
		newloc = [event locationInWindow];
		newloc = [self convertPoint:newloc fromView:nil];
#else // Original
		newloc = event->location;
		[self convertPoint:&newloc  fromView:NULL];
#endif
		warn = 0;
		for (j = 0;j < max;j++)
		{
			delta_t	*d;
			NXPoint	l;
			
			d = [deltaTable	elementAt:j];
			l = newloc;
			l.x = ((int)l.x - d->xoff) & -2;
			l.y = ((int)l.y - d->yoff) & -2;
			//
			// dragged selections off texture? if so, pull back the ones already lost.
			//
			if (l.x < 0 || l.y < 0 || l.x/2 > textures[ct].width || l.y/2 > textures[ct].height)
				warn = 1;
			d->p->r.origin = l;
			d->p->patchInfo.originx = l.x / 2;
			d->p->patchInfo.originy = textures[ct].height - 
								((l.y / 2) + (d->p->r.size.height / 2));

		}
		[ self		display ];
		[textureEdit_i	updateTexPatchInfo];
		[textureEdit_i	setWarning:warn];

#ifdef REDOOMED
	} while ([event type] != NSEventTypeLeftMouseUp);
#else // Original
	} while (event->type != NX_MOUSEUP);
#endif

	if ([[textureEdit_i	selectedTexturePatches] count] == 1)
	{
		delta_t *d;
		d = [deltaTable elementAt:0];
//		[textureEdit_i	setOldVars:d->p->patchInfo.originx + d->p->r.size.width/2
//					:(textures[ct].height - d->p->patchInfo.originy) - d->p->r.size.height/2];
		[textureEdit_i	setOldVars:d->p->patchInfo.originx + d->p->r.size.width/2
					:d->p->patchInfo.originy];
	}

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

@end
