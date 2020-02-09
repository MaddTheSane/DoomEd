// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"DoomProject.h"
#import	"SectorEditor.h"
#import	"SectorEditView.h"

@implementation SectorEditView

- drawSelf:(const NXRect *)rects :(int)rectCount
{
	sectordef_t	*s;
	flat_t	*f;
	NXPoint	p;
	NXRect	r;
	
	s = [sectorEdit_i		getSector];
		
	PSsetgray(NX_LTGRAY);
	r = NSMakeRect(0,0,128,200);

#ifndef REDOOMED // Original (Disable for ReDoomEd - disable grey background, leave transparent)
	NXRectFill(&r);
#endif
	
	//
	// Draw ceiling
	//
	if (!s->ceilingflat[0])
	{
		r = NSMakeRect(32,105,64,64);
		NXRectFill(&r);
	}
	else
	{
		f = [sectorEdit_i	getCeilingFlat];
		p.x = 32;
		p.y = 105;
		[f->image drawAtPoint:p fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1];
	}
	
	//
	// Draw floor
	//
	if (!s->floorflat[0])
	{
		r = NSMakeRect(32,31,64,64);
		NXRectFill(&r);
	}
	else
	{
		f = [sectorEdit_i	getFloorFlat];
		p.x = 32;
		p.y = 31;
		[f->image drawAtPoint:p fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1];
	}

	return self;
}

#ifndef REDOOMED  // Original (Disable for ReDoomEd - unnecessary/dead code)
- mouseDown:(NXEvent *)theEvent
{
	NXPoint	loc;
	int	oldwindowmask;
//	int ny, yoff;
//	sectordef_t	*s;
//	NXEvent	*event;
//	NXRect	r;

	oldwindowmask = [window addToEventMask:NX_LMOUSEDRAGGEDMASK];
	loc = theEvent->location;
	[self convertPoint:&loc	fromView:NULL];
	
#if 0	
	s = [sectorEdit_i		getSector];
	r.origin.x = 32;
	r.size.height = r.size.width = 64;

	//
	// Check ceiling
	//
	if (s->ceilingheight <= 200)
	{
		r.origin.y = s->ceilingheight/2 + 50;
		if (NSPointInRect(loc,r) == YES)
		{
			[sectorEdit_i	selectCeiling];
			yoff = loc.y - r.origin.y;
			do
			{
				event = [NXApp getNextEvent: NX_MOUSEUPMASK |									NX_MOUSEDRAGGEDMASK];
				loc = event->location;
				[self convertPoint:&loc	fromView:NULL];
				ny = (2 * (loc.y - yoff)) - 100;
				if (ny > 200)
					ny = 200;
				if (ny < 0)
					ny = 0;
				if (ny < s->floorheight)
					ny = s->floorheight;
				ny &= -8;
				s->ceilingheight = ny;
				[self setNeedsDisplay:YES];
				[sectorEdit_i	setCeiling:ny];
				
			} while (event->type != NX_MOUSEUP);
		}
	}
	
	if (s->floorheight >= 0)
	{
		r.origin.y = s->floorheight/2 - 14;
		if (NSPointInRect(loc,r) == YES)
		{
			[sectorEdit_i	selectFloor];
			yoff = (r.origin.y + r.size.height) - loc.y;
			do
			{
				event = [NXApp getNextEvent: NX_MOUSEUPMASK |									NX_MOUSEDRAGGEDMASK];
				loc = event->location;
				[self convertPoint:&loc	fromView:NULL];
				ny = (2 * (loc.y + yoff)) - 100;
				if (ny > 200)
					ny = 200;
				if (ny < 0)
					ny = 0;
				if (ny > s->ceilingheight)
					ny = s->ceilingheight;
				ny &= -8;
				s->floorheight = ny;
				[self setNeedsDisplay:YES];
				[sectorEdit_i	setFloor:ny];
				
			} while (event->type != NX_MOUSEUP);
		}
	}
#endif
	
	[window	setEventMask:oldwindowmask];
	return self;
}
#endif  // Original (Disable for ReDoomEd)

@end
