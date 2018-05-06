#import "BlockWorld.h"
#import	"DoomProject.h"

id		blockworld_i;
CompatibleStorage *sectors=nil;	// storage object of sectors
int		numsectors;
id		pan;

//define SHOWFILL

@implementation BlockWorld

/*
================
=
= init
=
================
*/

- init
{
	if (self = [super init]) {
	blockworld_i = self;
	sectors = [[CompatibleStorage alloc] 
				initCount: 	0 
				elementSize: 	sizeof(worldsector_t)
				description: 	NULL
			];
	}
	return self;
}

- sectorError: (NSString *)msg : (int)line1 : (int)line2
{
	[pan	orderOut:NULL];
	NSReleaseAlertPanel(pan);
	[editworld_i deselectAll];
	if (line1 != -1)
	{
		[editworld_i selectLine: line1];
		[editworld_i selectPoint: lines[line1].p1];
		[editworld_i selectPoint: lines[line1].p2];
	}
	if (line2 != -1)
	{
		[editworld_i selectLine: line2];
		[editworld_i selectPoint: lines[line2].p1];
		[editworld_i selectPoint: lines[line2].p2];
	}
	[editworld_i redrawWindows];
	NSRunAlertPanel(@"Sector error", @"%@", nil, nil, nil, msg);
	return self;
}



/*
===============================================================================

						WORLD PIXELATION

===============================================================================
*/
#define	WL_NORTH	0
#define	WL_EAST	1
#define	WL_SOUTH	2
#define	WL_WEST	3
#define	WL_MARK	4
#define	WL_NWSE	5
#define	WL_NESW	6

#define	WLSIZE		7
#define	SIDEBIT		0x8000

NSRect	wbounds;
unsigned short	*bmap=NULL;
int		brow, bwidth, bheight;
id		blockview;

void selectline (unsigned line)
{
	line--;
	if (line & SIDEBIT)
	{
		line &= ~SIDEBIT;
		lines[line].selected = 2;
		return;
	}
	
	lines[line].selected = 1;	
}


/*
===============
=
= floodline
=
===============
*/

void floodline (int startx, int y)
{
	int		x, firstx, lastx;
	int		line;
	unsigned short *dest;
	
	if (startx<0 || startx>=bwidth || y < 0 || y>=bheight)
	{
		NSRunAlertPanel(@"error", @"bad fill point", nil, nil, nil);
		return;
	}
	//
	// scan east until a wall is hit
	//
	x = startx-1;
	while (x<bwidth-1)
	{
		x++;
		dest = bmap + y*brow + x*WLSIZE;
		*(dest+WL_MARK) = 1;
#if SHOWFILL
		{
			NSRect	r;
			r.origin.x = x+0.15;
			r.origin.y = (bheight-1-y)+0.15;
			r.size.width = r.size.height = 0.5;
			NXEraseRect (&r);
		}
#endif

		if ((line = *(dest+WL_EAST)) != 0)
		{
			selectline (line);
			break;
		}
		else if (x<bwidth-1)
		{
			if ((line = *(dest+WLSIZE+WL_NWSE)) != 0)
			{
				selectline(line);
				break;
			}
			else if ((line = *(dest+WLSIZE+WL_NESW)) != 0)
			{
				selectline(line^SIDEBIT);
				break;
			}
		}
	}
	lastx = x;

	//
	// scan west until a wall is hit
	//
	x = startx;
	while (x>0)
	{
		dest = bmap + y*brow + x*WLSIZE;
		*(dest+WL_MARK) = 1;
#if SHOWFILL
		{
			NSRect	r;
			r.origin.x = x+0.15;
			r.origin.y = (bheight-1-y)+0.15;
			r.size.width = r.size.height = 0.5;
			NXEraseRect (&r);
		}
#endif

		if ((line = *(dest+WL_WEST)) != 0)
		{
			selectline (line);
			break;
		}
		else if (x>0)
		{
			if ((line = *(dest-WLSIZE+WL_NWSE)) != 0)
			{
				selectline(line^SIDEBIT);
				break;
			}
			else if ((line = *(dest-WLSIZE+WL_NESW)) != 0)
			{
				selectline(line);
				break;
			}
		}
		x--;
	}
	firstx = x;
	//
	// check the top and bottom pixels
	//
	if (firstx<0 || lastx>=bwidth || firstx>lastx)
	{
		NSRunAlertPanel(@"ERROR", @"bad fill span", nil, nil, nil);
		return;
	}

	for (x=firstx ; x<=lastx ; x++)
	{
		dest = bmap + y*brow + x*WLSIZE;

		if ((line = *(dest+WL_SOUTH)) != 0)
		{
			selectline (line);
		}
		else if ( y<bheight-1 && !*(dest+brow+WL_MARK))
		{
			if ((line = *(dest+brow+WL_NWSE)) != 0)
				selectline(line^SIDEBIT);
			else if ((line = *(dest+brow+WL_NESW)) != 0)
				selectline(line^SIDEBIT);
			else
				floodline (x,y+1);
		}

		if ((line = *(dest+WL_NORTH)) != 0)
		{
			selectline (line);
		}
		else if (y>0  && !*(dest-brow+WL_MARK))
		{
			if ((line = *(dest-brow+WL_NWSE)) != 0)
				selectline(line);
			else if ((line = *(dest-brow+WL_NESW)) != 0)
				selectline(line);
			else
				floodline (x,y-1);
		}
	}
	
}


/*
================
=
= drawBlockLine
=
================
*/

- (void)drawBlockLine: (int) linenum
{
	worldline_t	*line;
	int			x1, y1, x2, y2;
	NSPoint		*pt;
	int			left, right, top, bottom;
	unsigned short	*dest;
	int			temp, offset;
	int			dx, dy,ilength;
	CGFloat		length, x, y, xstep, ystep;
	
	line = &lines[linenum];
	pt = &points[line->p1].pt;
	x1 = (pt->x - wbounds.origin.x)/8;
	y1 = (pt->y - wbounds.origin.y)/8;
	pt = &points[line->p2].pt;
	x2 = (pt->x - wbounds.origin.x)/8;
	y2 = (pt->y - wbounds.origin.y)/8;
	
	if (x1 == x2)
	{
	// vertical line
		if (y1 < y2)
		{
			left = (linenum+1) | SIDEBIT;
		}
		else
		{
			left = linenum+1;
			temp = y1;
			y1 = y2;
			y2 = temp;
		}
			
		right = left ^ SIDEBIT;
		dest = bmap + (bheight-1-y1)*brow + x1*WLSIZE;
		while (y1 < y2)
		{
			*(dest+WL_WEST) = right;
			*(dest-WLSIZE+WL_EAST) = left;
			dest -= brow;
			y1++;
		}
		return;
	}
	
	if (y1 == y2)
	{
	// horizontal line
		if (x1 < x2)
		{
			top = (linenum+1) | SIDEBIT;
		}
		else
		{
			top = linenum+1;
			temp = x1;
			x1 = x2;
			x2 = temp;
		}
			
		bottom = top ^ SIDEBIT;
		dest = bmap + (bheight-1-y1)*brow + x1*WLSIZE;
		while (x1 < x2)
		{
			*(dest+WL_SOUTH) = top;
			*(dest+brow+WL_NORTH) = bottom;
			dest += WLSIZE;
			x1++;
		}
		return;
	}
	
	// sloping line
	
	if (x1 < x2)
	{
		if (y1 < y2)
		{
			offset = WL_NESW;
			left = linenum+1;
		}
		else
		{
			offset = WL_NWSE;
			left = linenum+1;
		}
	}
	else
	{
		if (y1 < y2)
		{
			offset = WL_NWSE;
			left = (linenum+1)|SIDEBIT;
		}
		else
		{
			offset = WL_NESW;
			left = (linenum+1)|SIDEBIT;
		}
	}
	
	dx = x2 - x1;
	dy = y2 - y1;
	length = sqrt (dx*dx + dy*dy);
	xstep = dx/length;
	ystep = dy/length;
	x = x1+xstep/2;
	y = y1+ystep/2;
	ilength = length+0.5;
	do
	{
		y1 = y;
		x1 = x;
		dest = bmap + (bheight-1-y1)*brow + x1*WLSIZE;
		*(dest+offset) = left;
		x+= xstep;
		y+= ystep;
	} while (--ilength > 0);

	return;
}


/*
================
=
= displayBlockMap
=
================
*/

- (void)displayBlockMap
{
	NSRect	aRect;
	id		window;
	unsigned char		*planes[5];
	int		i,size;
	unsigned short	*src, *dest;

	aRect = NSMakeRect(100, 100, brow / WLSIZE, bheight);
	window = [[NSWindow alloc] initWithContentRect: aRect
	                           styleMask: NSTitledWindowMask
				   backing: NSBackingStoreRetained
	//buttonMask:	NX_MINIATURIZEBUTTONMASK|NX_CLOSEBUTTONMASK
				   defer: NO];

	[window display];
	[window orderFront:nil];

	blockview = [window contentView];
	size = brow/WLSIZE*bheight;
	planes[0] = malloc(size * 2);
	dest = (unsigned short *) planes[0];
	src = bmap;
	for (i = 0 ; i < size; i++)
	{
		if (src[WL_MARK])
			*dest = 0xff;
		else if (src[0] || src[1] || src[2] || src[3] || src[WL_NWSE] || src[WL_NESW])
			*dest = 0xffff;
		else
			*dest = 0;
		src += WLSIZE;
		dest++;
	}

	aRect.origin.x = aRect.origin.y = 0;

	[blockview lockFocus]; 
	/* TODO
	NXDrawBitmap(
		&aRect,  
		bwidth, 
		bheight,
		4,
		3,
		16,
		bwidth*2,
		NO,
		NO,
		NX_RGBColorSpace,
		planes
	);
	*/
	[blockview unlockFocus]; 
	
	PSwait();

	free(planes[0]);
}


/*
================
=
= createBlockMap
=
================
*/

- (void)createBlockMap
{
	int	i, size;
	
//
// find the dimensions of the world and allocate an empty map
//
	wbounds = [editworld_i getBounds];
	if (bmap)
		free(bmap);
	bwidth = wbounds.size.width/8;
	bheight = wbounds.size.height/8;
	brow = bwidth * WLSIZE;
	size = brow* bheight * 2;
	bmap = malloc (size);
	memset (bmap,0,size);	

//
// draw all the lines into the map
//
	for (i=0 ; i<numlines ; i++)
	{
		if (lines[i].selected != -1)
			[self drawBlockLine: i];
	}
}


/*
================
=
= floodFillSector
=
================
*/

- (void)floodFillSector: (NSPoint *)pt
{
	int	x1, y1;
	
	[self createBlockMap];
	[editworld_i deselectAll];
	x1 = (pt->x - wbounds.origin.x)/8;
	y1 = (pt->y - wbounds.origin.y)/8;
#if SHOWFILL
	[self displayBlockMap];
	[blockview lockFocus];
#endif
	floodline (x1, bheight-1-y1);
#if SHOWFILL
	[blockview unlockFocus];
#endif
	[editworld_i redrawWindows];
//	free(bmap);
}

/*
================
=
= makeSector
=
= groups all selected sides into a sector
= Returns NO and presents an error dialog if there is an error
=
================
*/

- (BOOL)makeSector
{
	worldside_t	*side;
	worldline_t	*line;
	int		i, backline, frontline;
	worldsector_t	new;

	new.lines = [ [CompatibleStorage alloc]
		initCount: 	0
		elementSize: 	sizeof(int)
		description: 	NULL
	];

	backline = -1;
	frontline = -1;
	line = lines;
	for (i=0;i<numlines;i++,line++)
	{
		if (line->selected < 1)
			continue;
		if (line->selected == 2 && !(line->flags&ML_TWOSIDED))
		{
			backline = i;
			continue;
		}
		side = &line->side[line->selected-1];
		if (frontline == -1)
			memcpy (&new.s, &side->ends, sizeof(sectordef_t));
		else
			if (bcmp (&new.s, &side->ends, sizeof(sectordef_t)))
			{
				[new.lines release];
				[self sectorError: @"Line sectordefs differ" : i : frontline];
				return NO;
			}
		[new.lines addElement: &i];
		frontline = i;
		if (side->sector != -1)
		{
			[new.lines release];
			[self sectorError:@"Line side grouped into multiple sectors" : i : -1];
			return NO;
		}
		else
			side->sector = numsectors;
	}
	
	if (backline >-1 && frontline > -1)
	{
		[new.lines release];
		[self sectorError:@"Inside and outside lines grouped together" : backline : frontline];
		return NO;
	}
	if (frontline > -1)
	{
		[sectors addElement: &new];
		numsectors++;
	}
	else
		[new.lines release];

	
	return YES;
}

/*
================
=
= connectSectors
=
================
*/

- (BOOL)connectSectors
{
	NSInteger		i,x,y;
	worldline_t		*line;
	unsigned short	*test;
	NSInteger		count;
	worldsector_t	*sector;

//
// clear all sector marks
//
	count = [sectors count];
	for (i=0 ; i<count ; i++)
	{
		sector = [sectors elementAt: i];
		[sector->lines release];
	}
	[sectors empty];
	for (i=0 ; i<numlines ; i++)
	{
		lines[i].side[0].sector = -1;
		lines[i].side[1].sector = -1;
	}
	numsectors = 0;
	
//
// flood fill everything
//
	[self createBlockMap];
#if SHOWFILL
	[self displayBlockMap];
#endif

	pan = NSGetAlertPanel(@"One moment",
		@"Filling block map",
		nil, nil, nil);
	[pan display];
	[pan orderFront: NULL];
	PSwait ();

	test = bmap;
	for (y=0 ; y<bheight; y++)
		for (x=0 ; x<bwidth; x++, test+=WLSIZE)
			if (!test[WL_MARK] && !test[WL_NWSE] && !test[WL_NESW] )
			{
				[editworld_i deselectAll];
#if SHOWFILL
				[blockview lockFocus];
#endif
				floodline (x, y);
#if SHOWFILL
				[blockview unlockFocus];
#endif
				if (![self makeSector])
				{
					return NO;
				}
			}
			
//
// check to make sure all line sides were grouped
//
	line = lines;
	for (i=0;i<numlines;i++,line++)
	{
		if (line->selected < 1)
			continue;
		if (line->side[0].sector == -1 || 
		((line->flags&ML_TWOSIDED) && line->side[1].sector == -1) )
		{
			[self sectorError:@"Line side not grouped" : (int)i : -1];
			return NO;
		}
	}
	
	[editworld_i deselectAll];
	
	[pan	orderOut:NULL];
	NSReleaseAlertPanel(pan);
	PSwait ();
	return YES;
}


@end

