// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "EditWorld.h"
#import "idfunctions.h"
#import "MapWindow.h"
#import "MapView.h"
#import "Coordinator.h"
#import "ThingPanel.h"
#import "LinePanel.h"
#import "TextureEdit.h"
#import	"DoomProject.h"

#ifdef REDOOMED
#   import "../RDEdoombsp.h"
#endif

//=============================================================================

#ifdef REDOOMED
    // Editworld has some methods that use the same names as methods defined
    // by native Cocoa classes, but with different method signatures, so
    // specify the class for the editworld_i global to prevent the compiler
    // from using the wrong signatures
    EditWorld   *editworld_i;
#else // Original
    id			editworld_i;
#endif

NSInteger			numpoints, numlines, numthings;

worldpoint_t	*points;
worldline_t	*lines;
worldthing_t	*things;

static int LineSideToPoint(worldline_t *line, NXPoint *pt);

//=============================================================================

#define	BASELISTSIZE	128

/// Returns a 0 for front and a 1 for back
int	LineSideToPoint (worldline_t *line, NXPoint *pt)
{
	NXPoint	*p1, *p2;
	float		slope, yintercept;
	BOOL	direction, test;

	p1 = &points[line->p1].pt;
	p2 = &points[line->p2].pt;
	
	if (p1->y == p2->y)
		return (p1->x < p2->x) ^ (pt->y < p1->y);
	if (p1->x == p2->x)
		return (p1->y < p2->y) ^ (pt->x > p1->x);

	slope = (p2->y - p1->y) / (p2->x - p1->x);
	yintercept = p1->y - slope*p1->x;

//
// for y > mx+b, substitute in the normal point, which is on the front
//
	direction =  line->norm.y > slope*line->norm.x + yintercept ;
	test = pt->y > slope*pt->x + yintercept;
	
	if (direction == test)
		return 0;		// front side
	
	return 1;			// back side
}


int LineByPoint (NXPoint *ptin, int *side)
{
	NXPoint	ptp,*pt;
	int		l;
	NXPoint	*p1, *p2;
	float		frac, distance, bestdistance, xintercept;
	int		bestline=0;
	
	ptp = *ptin;
	pt = &ptp;		// quick, stupid hack to prevent modifying values in place
	
	pt->x += 0.5;
	pt->y += 0.5;
		
//
// find the closest line to the given point
//
	bestdistance = MAXFLOAT;
	for (l=0 ; l<numlines ; l++)
	{
		if (lines[l].selected == -1)
			continue;
		
		p1 = &points[lines[l].p1].pt;
		p2 = &points[lines[l].p2].pt;
		
		if (p1->y == p2->y)
			continue;
			
		if (p1->y < p2->y)
		{
			frac = (pt->y - p1->y) / (p2->y - p1->y);
			if (frac<0 || frac>1)
				continue;
			xintercept = p1->x + frac*(p2->x - p1->x);
		}
		else
		{
			frac = (pt->y - p2->y) / (p1->y - p2->y);
			if (frac<0 || frac>1)
				continue;
			xintercept = p2->x + frac*(p1->x - p2->x);
		}
		
		distance = fabs(xintercept - pt->x);
		if (distance < bestdistance)
		{
			bestdistance = distance;
			bestline = l;
		}
	}
	
//
// if no line is intercepted, the point was outside all areas
//
	if (bestdistance == MAXFLOAT)
	{
		*side = 0;
		return 0;		// this should be -1, but the program doesn't check
	}
		
	*side = LineSideToPoint (&lines[bestline], pt);

	return bestline;
}


@implementation EditWorld

@synthesize loaded;

@synthesize dirty;

- (BOOL)dirtyPoints
{
	if (dirtypoints)
	{
		dirtypoints = false;
		return true;
	}
	
	return dirtypoints;
}


/*
======================
=
= init
=
=======================
*/

- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	editworld_i = self;
	
//
// set up local structures
//
	windowlist_i = [[NSMutableArray alloc] init];
	numpoints = numlines = numthings = 0;
	pointssize = linessize = thingssize = texturessize = BASELISTSIZE;

	points = malloc (pointssize*sizeof(worldpoint_t));
	lines = malloc (linessize*sizeof(worldline_t));
	things = malloc (thingssize*sizeof(worldthing_t));

	copyThings_i	= [[Storage	alloc]
					initCount:		0
					elementSize:	sizeof(worldthing_t)
					description:	NULL];
	copyLines_i	= [[Storage	alloc]
					initCount:		0
					elementSize:	sizeof(copyline_t)
					description:	NULL];

	saveSound = [[NSSound soundNamed:@"DESave"] retain];
	
	return self;
}

- appWillTerminate: sender
{
// FIXME: prompt to save map if dirty
	if ([windowlist_i	count] > 0)
		[[windowlist_i	objectAtIndex:0]	saveFrameUsingName:WORLDNAME];
	[self release];
	return self;
}


/*
==================
=
= loadWorldFile:
=
==================
*/

- (BOOL)loadWorldFile: (char const *)path
{
	FILE	*stream;
	BOOL	ret;
	int		version;

	strncpy(pathname,path,sizeof(pathname));
	dirtyrect.size.width = dirtyrect.size.height = 0;
	boundsdirty = YES;
	
//
// load the file
//
	numpoints = numlines = numthings = 0;

//
// identify which map version the file is
//		
	stream = fopen (pathname,"r");
	if (!stream)
	{
		NSRunAlertPanel (@"Error",@"Couldn't open %s",NULL,NULL,NULL,pathname);
		return NO;
	}
	version = -1;
	fscanf (stream, "WorldServer version %d\n", &version);
	if (version == 0)
	{	// empty file -- clear stuf out
		
		ret = YES;
	}
	else if (version == 4)
		ret = [self loadV4File: stream];
	else
	{
		fclose (stream);
		NSRunAlertPanel (@"Error",@"Unknown file version '%d' for %s",NULL,NULL,NULL,version, pathname);
		return NO;
	}

	if (!ret)
	{
		fclose (stream);
		NSRunAlertPanel (@"Error",@"Couldn't parse file %s",NULL,NULL,NULL,pathname);
		return NO;
	}
	
	fclose (stream);
	dirty = NO;
	dirtypoints = YES;		// a connection matrix will be build for flood filling
//
// create a new window
//
	loaded = YES;
	[self newWindow:self];
	copyLoaded = 1;

	return YES;
}


/// Frees all resources so another world can be loaded
- (void)closeWorld
{
	if ([doomproject_i	mapDirty])
	{
		NSInteger val;
		
		val = NSRunAlertPanel(NSLocalizedString(@"Hey!", @"Hey!"),@"Your map has been modified! Save it?",
			NSLocalizedString(@"Yes", @"Yes"),NSLocalizedString(@"No", @"No"),NULL);
		if (val == NSAlertDefaultReturn)
			[self saveWorld:NULL];
		[doomproject_i setMapDirty:FALSE];
	}	

	[windowlist_i.firstObject saveFrameUsingName:WORLDNAME];

#ifdef REDOOMED
	// close the window
	[windowlist_i.firstObject performClose: self];
#endif

	[windowlist_i removeAllObjects];
	[windowlist_i release];
	windowlist_i = [[NSMutableArray alloc] init];
		
	numpoints = numlines = numthings = 0;
	loaded = NO;
}


#pragma mark - MENU TARGETS

/*
=====================
=
= newWindow:
=
=====================
*/

- (IBAction)newWindow:sender
{
	MapWindow *win;
	
	if (!loaded)
	{
		NSRunAlertPanel (@"Error",@"No world open",NULL,NULL,NULL);
		return;
	}
	
			
	win = [[MapWindow alloc] initFromEditWorld];
	if (!win)
		return;
		
	[windowlist_i addObject: win];

#ifndef REDOOMED // Original (Disable for ReDoomEd - MapWindow instances are now their own delegates)
	[win setDelegate: self];
#endif

	[win setTitleAsFilename: pathname];
	[win	setFrameUsingName:WORLDNAME];
	[win setViewsNeedDisplay:YES];
	[win makeKeyAndOrderFront:self];
}

///	Save DoomEd map and run BSP program
- (IBAction)saveDoomEdMapBSP:sender
{
#ifdef REDOOMED
	// prevent buffer overflows: increased the buffer sizes of strcpy() destination
    // strings, toPath & fromPath, to match the buffer sizes of their source strings,
    // pathname & mapwads (1024)
	char		toPath[1024];
	char		fromPath[1024];
	char        *doombsp_args[3];
#else // Original
	char		toPath[128];
	char		fromPath[128];
#endif
	int			err;
	FILE		*stream;
	id			panel;
	
	if (!loaded)
	{
		NSRunAlertPanel (@"Error",@"No world open",NULL,NULL,NULL);
		return;
	}

	printf ("Saving DoomEd map\n");
	BackupFile (pathname); 
	stream = fopen (pathname,"w");
	[self saveFile: stream];
	fclose (stream);
	
	printf("Running DoomBSP on %s\n",pathname);
	strcpy( fromPath, pathname);
	strcpy( toPath, mapwads);

	// prevent buffer overflows: *sprintf() -> *snprintf() in cases where input strings
	// might be too long for the destination buffer
	panel = NSGetAlertPanel(NSLocalizedString(@"Wait...", @"Wait..."),@"Please wait while I BSP process this map.\n\nMap: %s\nMapWADdir: %s\nBSPprogram:%s\nHost: %s",NULL,NULL,NULL, fromPath,toPath,bspprogram,bsphost);
	[panel	orderFront:NULL];
	NXPing();

	// the doombsp tool's sources are embedded into ReDoomEd, and called via RDEdoombsp_main()
	doombsp_args[0] = bspprogram;
	doombsp_args[1] = fromPath;
	doombsp_args[2] = toPath;

	err = RDEdoombsp_main(3, doombsp_args);

	if (err)
	{
		[panel	orderOut:NULL];
		NSReleaseAlertPanel(panel);

		return;
	}

	[panel	orderOut:NULL];
	NSReleaseAlertPanel(panel);
	[doomproject_i	setMapDirty:FALSE];
	[saveSound	play];
}


/*
=====================
=
= saveWorld:
=
=====================
*/

- (IBAction)saveWorld:sender
{
	FILE			*stream;
	id			pan;
	
	if (!loaded)
	{
		NSRunAlertPanel (@"Error",@"No world open",NULL,NULL,NULL);
		return;
	}
	
	pan = NSGetAlertPanel (@"One moment",@"Saving",NULL,NULL,NULL);
	[pan display];
	[pan orderFront: NULL];
	NXPing ();

	printf ("Saving DoomEd map\n");
	BackupFile (pathname); 
	stream = fopen (pathname,"w");
	[self saveFile: stream];
	fclose (stream);
//	dirty = NO;
	[doomproject_i	setMapDirty:FALSE];
	
	[pan	orderOut:NULL];
	NSReleaseAlertPanel(pan);
}


/*
=====================
=
= print:
=
=====================
*/

- (IBAction)print: sender
{
#ifdef REDOOMED
	// use MapWindow* typecast so compiler finds correct signature for mapView method
	[[(MapWindow *) [NXApp mainWindow] mapView] print: sender];
#else // Original
	[[[NXApp mainWindow] mapView] printPSCode: sender];
#endif
}



#pragma mark - VISUAL RELATED METHODS
	

/*
====================
=
= updateLineNormal:
=
= Updates the coordinates of the line normal
=
====================
*/

/// Updates the coordinates of the line normal
- (void)updateLineNormal:(int) num
{
	worldline_t	*line;
	NXPoint	*p1, *p2;
	float		dx, dy, length;

	line = &lines[num];
	
// FIXME: make two normals for two sided lines?

	p1 = &points[line->p1].pt;
	p2 = &points[line->p2].pt;
	
	dx = p2->x - p1->x;
	dy = p2->y - p1->y;
	length = sqrt (dx*dx + dy*dy)/LINENORMALLENGTH;
	line->mid.x = p1->x + dx/2;
	line->mid.y = p1->y + dy/2;
	line->norm.x = line->mid.x + dy/length;
	line->norm.y = line->mid.y - dx/length;
}



/*
================
=
= addPointToDirtyRect:
=
================
*/

- addPointToDirtyRect: (NXPoint *)pt
{
	IDEnclosePoint (&dirtyrect, pt);
	return self;
}



/// The rect around the two points is added to the dirty rect.
///
/// Update things adds directly to the dirty rect
- addToDirtyRect: (int)p1 : (int)p2
{
	[self addPointToDirtyRect: &points[p1].pt];
	[self addPointToDirtyRect: &points[p2].pt];
	return self;
#if 0
	NXRect	new;
	NXPoint	*pt1, *pt2;
	
	pt1 = &points[p1].pt;
	pt2 = &points[p2].pt;
	
	if (pt1->x < pt2->x)
	{
		new.origin.x = pt1->x;
		new.size.width = pt2->x - pt1->x+1;
	}
	else
	{
		new.origin.x = pt2->x;
		new.size.width = pt1->x - pt2->x+1;
	}
	
	if (pt1->y < pt2->y)
	{
		new.origin.y = pt1->y;
		new.size.height = pt2->y - pt1->y+1;
	}
	else
	{
		new.origin.y = pt2->y;
		new.size.height = pt1->y - pt2->y+1;
	}

	dirtyrect = NSUnionRect (new, dirtyrect);
#endif
	return self;
}



#pragma mark - WINDOW STUFF
// FIXME: Map window is its own delegate now, this needs to be done with a message

- (void)windowWillClose: sender
{
	if ([doomproject_i	mapDirty])
	{
		NSInteger	val;
		
		val = NSRunAlertPanel(NSLocalizedString(@"Hey!", @"Hey!"),@"Your map has been modified! Save it?",
			NSLocalizedString(@"Yes", @"Yes"),NSLocalizedString(@"No", @"No"),NULL);
		if (val == NSAlertDefaultReturn)
			[self	saveWorld:NULL];

#ifdef REDOOMED
		// clear the mapdirty flag, otherwise another "map has been modified" alert
		// will display when -[EditWorld closeWorld] is called
		[doomproject_i	setMapDirty:FALSE];
#endif
	}
	
	[[windowlist_i	objectAtIndex:0] saveFrameUsingName:WORLDNAME];
	[windowlist_i removeObject: sender];

//	[self	closeWorld];
}


- (void)updateWindows
{
	if (!dirtyrect.size.width)
		return;		// nothing to update

	for (MapWindow *win in windowlist_i.reverseObjectEnumerator) {
		[win reDisplay: &dirtyrect];
	}
		
	dirtyrect.size.width = dirtyrect.size.height = 0;
	[linepanel_i updateLineInspector];
	[thingpanel_i updateThingInspector];
}

- (void)redrawWindows
{
	[windowlist_i makeObjectsPerformSelector: @selector(display)];

	dirtyrect.size.width = dirtyrect.size.height = 0;
	[linepanel_i updateLineInspector];
	[thingpanel_i updateThingInspector];
}

- getMainWindow
{
	return windowlist_i.firstObject;
}


#pragma mark - RETURN INFORMATION


#define BOUNDSBORDER	128

- (void)getBounds: (NXRect *)theRect
{
	int		p;
	CGFloat		x,y,right, left, top, bottom;
	
	if (boundsdirty)
	{
		right = top = -CGFLOAT_MAX;
		left = bottom = CGFLOAT_MAX;
		
		for (p=0 ; p<numpoints ; p++)
		{
			x = points[p].pt.x;
			y = points[p].pt.y;
			if (x<left)
				left = x;
			if (x>right)
				right = x;
			if (y<bottom)
				bottom = y;
			if (y>top)
				top = y;
		}

		bounds.origin.x = left - BOUNDSBORDER;
		bounds.origin.y = bottom - BOUNDSBORDER;
		bounds.size.width = right -left + BOUNDSBORDER*2 ;
		bounds.size.height = top -bottom + BOUNDSBORDER*2 ;
		
		boundsdirty = NO;
	}
	
	if (bounds.size.width < 0)
	{
		bounds.origin.x = bounds.origin.y = 0;
		bounds.size.width = bounds.size.height = 0;
	}
	
	*theRect = bounds;
}


/*
===============================================================================

						NEW DATA ALLOCATION METHODS

FIXME: make these scan for deleted entries

===============================================================================
*/

// allocate a point even if it is a duplicate
- (int)allocatePoint: (NXPoint *)pt
{
// add a new point
	
	if (numpoints == pointssize)
	{
		pointssize += 128;		// add space to array
		points = realloc (points, pointssize*sizeof(worldpoint_t));
	}
	
// set default values
	points[numpoints].pt = *pt;
	points[numpoints].refcount = 1;
	points[numpoints].selected = 0;
	
	numpoints++;
	dirtypoints = true;		// connection matrix will need to be recalculated
	
	return (int)(numpoints-1);	
}


/// If an existing point can be used, it's refcount is incremented
- (int)newPoint: (NXPoint *)pt
{
	int	i;
	worldpoint_t	*check;

	boundsdirty = YES;
// round the point to integral values
	pt->x = (int)(pt->x);
	pt->y = (int)(pt->y);
	
// use an existing point if equal

	check = points;
	for (i=0 ; i<numpoints ; i++,check++)
		if (check->selected != -1 && check->pt.x == pt->x && check->pt.y == pt->y)
		{
			check->refcount++;
			return i;
		}

	return [self allocatePoint: pt];
}


/// returns the slot the line was stuck in
- (int)newLine:(worldline_t *)data from: (NXPoint *)p1 to:(NXPoint *)p2
{	
	if (numlines == linessize)
	{
		linessize += 128;		// add space to array
		lines = realloc (lines, linessize*sizeof(worldline_t));
	}

	lines[numlines].selected = -1;	// signal change that it is a new addition

	numlines++;

	data->p1 = [self newPoint: p1];
	data->p2 = [self newPoint: p2];
	
	dirtypoints = true;		// connection matrix will need to be recalculated

	[self changeLine: (int)(numlines-1) to: data];

	return (int)(numlines - 1);
}


/// The type and origin should be set so the dirty rects can be set
- (int)newThing: (worldthing_t *)thing
{	
	if (numthings == thingssize)
	{
		thingssize += 128;		// add space to array
		things = realloc (things, thingssize*sizeof(worldthing_t));
	}
	
	things[numthings].selected = -1;	// signal change that it is a new addition
	
	numthings++;

	[self changeThing: numthings-1 to: thing];
	
	return numthings-1;
}


//=============================================================================



/// If a point is not used any more, remove it
- dropPointRefCount: (int)p
{
	if (--points[p].refcount)
		return self;
		
//	printf ("removing point %i\n",p);	// DEBUG
	points[p].selected = -1;
	
	return self;
}


 #pragma mark - SELECTION MODIFICATION METHODS

/// deletes and recreates the selected lines with an oposite direction
- (IBAction)flipSelectedLines: sender
{
	worldline_t	line;
	int			i;
	NXPoint		p1,p2;
	
	if (!loaded)
		return;
	
// FIXME: much easier now
	
	for (i=0 ; i<numlines ; i++)
		if (lines[i].selected == 1)
		{
			line = lines[i];
			p1 = points[line.p1].pt;
			p2 = points[line.p2].pt;
			line.selected = -1;
			[self changeLine: i to: &line];		// delete the old line
			line.selected = 0;
			[self newLine: &line from: &p2 to: &p1];  // add a new one
		}
		
	[self updateWindows];
}

/// All selected points that are at the same location will be set to the same point
- (IBAction)fusePoints: sender
{
	int	i, j, k;
	NXPoint	*p1, *p2;
	worldline_t	*line;
	
	for (i=0 ; i<numpoints ; i++)
	{
		if (points[i].selected != 1)
			continue;
		p1 = &points[i].pt;
		//
		// find any points that are on the same spot as point i		//
		for (j=0 ; j<numpoints ; j++)
		{
			if (points[j].selected == -1 || j == i)
				continue;
			p2 = &points[j].pt;
			if (p1->x != p2->x || p1->y != p2->y)
				continue;
			//
			// find all lines that use point j
			//
			for (k=0 ; k<numlines ; k++)
			{
				line = &lines[k];
				if (line->selected == -1)
					continue;
				if (line->p1 == j)
				{
					line->p1 = i;
					points[i].refcount++;
				}
				else if (line->p2 == j)
				{
					line->p2 = i;
					points[i].refcount++;
				}
			}
			points[j].selected = -1;		// remove the duplicate point
		}
	}
	
	[self updateWindows];
}


/// All selected points that have a refcount greater than one will have clones made
- (IBAction)seperatePoints: sender
{
	int	i, k;
	worldline_t	*line;
	
	for (i=0 ; i<numpoints ; i++)
	{
		if (points[i].selected != 1)
			continue;
		if (points[i].refcount < 2)
			continue;
		for (k=0 ; k<numlines ; k++)
		{
			line = &lines[k];
			if (line->selected == -1)
				continue;
			if (line->p1 == i)
			{
				if (points[i].refcount == 1)
					break;			// all the other uses have been seperated
				line->p1 = [self allocatePoint: &points[i].pt];
				points[i].refcount--;
			}
			else if (line->p2 == i)
			{
				if (points[i].refcount == 1)
					break;			// all the other uses have been seperated
				line->p2 = [self allocatePoint: &points[i].pt];
				points[i].refcount--;
			}
		}
	}
	
	[self updateWindows];
}

/*
===============
=
= cut:
=
===============
*/

///
/// store copies of all stuff to be copied!
///
- (void)storeCopies
{
	int	i;
	NXRect	r;
	copyline_t	cl;
	
	r = [[[NXApp mainWindow] contentView] documentVisibleRect];
	copyCoord = r.origin;
	[copyThings_i		empty];
	[copyLines_i		empty];
	
	for (i=0;i<numthings;i++)
		if (things[i].selected == 1)
			[copyThings_i		addElement:&things[i]];
	for (i=0;i<numlines;i++)
		if (lines[i].selected == 1)
		{
			cl.l = lines[i];
			cl.p1 = points[cl.l.p1].pt;
			cl.p2 = points[cl.l.p2].pt;
			[copyLines_i		addElement:&cl];
		}
	
	copyLoaded = 0;
}

///
/// deselect everything after copying
///
- (void)copyDeselect
{
	int	i;

	for (i=0;i<numthings;i++)
		if (things[i].selected == 1)
			[self	deselectThing:i];
	for (i=0;i<numlines;i++)
		if (lines[i].selected == 1)
			[self	deselectLine:i];
	for (i=0;i<numpoints;i++)
		if (points[i].selected == 1)
			[self	deselectPoint:i];
}

///
/// find center point of copied stuff
///
- (NXPoint)findCopyCenter
{
	worldthing_t	*t;
	copyline_t	*L;
	NXPoint	p;
	NSInteger	i,max,xmin,ymin,xmax,ymax;
	
	xmin  = ymin  = xmax = ymax = 0;
	max = [copyThings_i	count];
	for (i=0;i < max;i++)
	{
		t = [copyThings_i	elementAt:i];
		xmin = MIN(xmin, t->origin.x);
		ymin = MIN(ymin, t->origin.y);
		xmax = MAX(xmax, t->origin.x);
		ymax = MAX(ymax, t->origin.y);
	}
	
	max = [copyLines_i	count];
	for (i=0;i < max;i++)
	{
		L = [copyLines_i	elementAt:i];
		xmin = MIN(xmin, L->p1.x);
		ymin = MIN(ymin, L->p1.y);
		xmax = MAX(xmax, L->p1.x);
		ymax = MAX(ymax, L->p1.y);
		
		xmin = MIN(xmin, L->p2.x);
		ymin = MIN(ymin, L->p2.y);
		xmax = MAX(xmax, L->p2.x);
		ymax = MAX(ymax, L->p2.y);
	}

	p.x = (xmax + xmin) / 2;
	p.y = (ymax + ymin) / 2;
	return p;
}

- (IBAction)cut: sender
{
	[self	storeCopies];
	[self	delete:NULL];
	[self	copyDeselect];
	[self updateWindows];
}


/*
===============
=
= copy:
=
===============
*/

- (IBAction)copy: sender
{
	[self	storeCopies];
	[self	copyDeselect];
	[self updateWindows];
}


/*
===============
=
= paste:
=
===============
*/

- (IBAction)paste: sender
{
	int		xadd,yadd,i, index;
	NSInteger max;
	NXRect	r;
	worldthing_t	*t, t1;
	copyline_t	*L;
	NXPoint	p1,p2;

	[self	copyDeselect];
	r = [[[NXApp mainWindow] contentView] documentVisibleRect];
	if (copyLoaded)
	{
		copyCoord = [self	findCopyCenter];
		copyCoord.x -= r.size.width / 2;
		copyCoord.y -= r.size.height / 2;
		copyLoaded = 0;
	}

	xadd = (int)(r.origin.x - copyCoord.x + 16) & -8;
	yadd = (int)(r.origin.y - copyCoord.y + 16) & -8;
	
	max = [copyThings_i	count];
	for (i=0;i < max;i++)
	{
		t = [copyThings_i elementAt:i];
		t1 = *t;
		t1.origin.x += xadd;
		t1.origin.y += yadd;
		index = [self	newThing:&t1];
		[self	selectThing:index];
	}

	max = [copyLines_i	count];
	for (i=0;i < max;i++)
	{
		L = [copyLines_i	elementAt:i];
		p1 = L->p1;
		p2 = L->p2;
		p1.x += xadd;
		p1.y += yadd;
		p2.x += xadd;
		p2.y += yadd;
		index = [self	newLine:&L->l  from:&p1  to:&p2];
		[self	selectLine:index];
		[self	selectPoint:lines[index].p1];
		[self	selectPoint:lines[index].p2];
	}
	
	[self updateWindows];
}


/*
===============
=
= delete:
=
===============
*/

- (IBAction)delete: sender
{
	int	i;
	worldline_t	line;
	worldthing_t	thing;
	
// delete any lines that have both end points selected
	for (i=0 ; i<numlines ; i++)
	{
		if (lines[i].selected < 1)
			continue;
		if ( points[ lines[i].p1 ].selected != 1 ||  points[ lines[i].p2 ].selected != 1 )
			continue;
		line = lines[i];
		line.selected = -1;	// remove the line
		[self changeLine: i to: &line];
	}
	
// delete any selected things
	for (i=0 ; i<numthings ; i++)
		if ( things[ i].selected == 1)
		{
			thing = things[i];
			thing.selected = -1;	// remove the thing
			[self changeThing: i to: &thing];
		}

	[self updateWindows];
}



/// MARK: - CHANGE METHODS
/// Updates dirty rect based on old and new positions

/*
====================
=
= changePoint: to:
=
====================
*/

- changePoint: (int) num to: (worldpoint_t *) data
{
	int	i;
	BOOL	moved = NO;
	
	boundsdirty = YES;
//printf ("changePoint: %i\n",num);
	if (num < numpoints)		// can't get a dirty rect from a single new point
	{		
		if (data->pt.x == points[num].pt.x && data->pt.y == points[num].pt.y)
		{	// point's position didn't change
			[self addToDirtyRect: num : num];
			moved = NO;
		}
		else
		{
		// the dirty rect encloses all the lines that use the point, both before and after the move
			for (i=0 ; i<numlines ; i++)
				if (lines[i].p1 == num || lines[i].p2 == num)
					[self addToDirtyRect: lines[i].p1 : lines[i].p2];
			moved = YES;
		}
	}

	if (num >= numpoints)
	{
		NSRunAlertPanel (NSLocalizedString(@"Error", @"Error"),@"Sent point %i with numpoints %li!",
						 NULL,NULL,NULL, num, (long)numpoints);
		[NXApp terminate:self];
	}
	
	points[num] = *data;

	if (moved) 
	{
		dirtypoints = true;		// connection matrix will need to be rebuilt
		for (i=0 ; i<numlines ; i++)
			if (lines[i].selected != -1 && ( lines[i].p1 == num || lines[i].p2 == num) )
			{
				[self addToDirtyRect: lines[i].p1 : lines[i].p2];
				[self updateLineNormal: i];
			}
	}
	
				

	return nil;
}

/// Updates midpoint / normal and dirty rect
- changeLine: (int) num to: (worldline_t *)data
{
	boundsdirty = YES;
//printf ("changeLine: %i\n",num);
	if (num >= numlines)
	{
		NSRunAlertPanel (NSLocalizedString(@"Error", @"Error"),@"Sent line %i with numlines %li!",NULL,NULL,NULL, num, (long)numlines);
		[NXApp terminate:self];
	}

#ifdef REDOOMED
	// Bugfix: set mapdirty flag whenever a line changes (except for selection changes)
	if ((lines[num].p1 != data->p1)
		|| (lines[num].p2 != data->p2)
		|| (lines[num].special != data->special)
		|| (lines[num].tag != data->tag)
		|| (lines[num].flags != data->flags)
		|| (data->selected == -1)) // line is being deleted
	{
		if (![doomproject_i mapDirty])
		{
			[doomproject_i setMapDirty: TRUE];
		}
	}
#endif
	
// mark the old position of the line as dirty
	if (lines[num].selected != -1)
		[self addToDirtyRect: lines[num].p1 : lines[num].p2];

// change the line	
	lines[num] = *data;
		
	if (data->selected != -1)
	{
	// mark the new position of the line as dirty
		[self addToDirtyRect: lines[num].p1 : lines[num].p2];
	// update midpoint / normal point
		[self updateLineNormal: num];
	}
	else
	{
	// drop point refcounts
		[self dropPointRefCount: lines[num].p1];
		[self dropPointRefCount: lines[num].p2];
	}

	return nil;
}


/*
====================
=
= changeThing: to:
=
====================
*/

- changeThing: (int)num to: (worldthing_t *)data
{
	NXRect	drect;
	
	boundsdirty = YES;
//printf ("changeThing: %i\n",num);
	if (num >= numthings)
	{
		NSRunAlertPanel (NSLocalizedString(@"Error", @"Error"),@"Sent thing %i with numthings %li!",NULL,NULL,NULL, num, (long)numthings);
		[NXApp terminate:self];
	}

#ifdef REDOOMED
	// Bugfix: set mapdirty flag whenever a thing changes (except for selection changes)
	if (!NSEqualPoints(things[num].origin, data->origin)
		|| (things[num].angle != data->angle)
		|| (things[num].type != data->type)
		|| (things[num].options != data->options)
		|| (data->selected == -1)) // thing is being deleted
	{
		if (![doomproject_i mapDirty])
		{
			[doomproject_i setMapDirty: TRUE];
		}
	}
#endif
	
// mark the old position as dirty
	if (things[num].selected != -1)
	{
		drect = NSMakeRect(data->origin.x - THINGDRAWSIZE/2
		, data->origin.y - THINGDRAWSIZE/2,THINGDRAWSIZE, THINGDRAWSIZE);
		dirtyrect = NSUnionRect (drect, dirtyrect);
	}

// change the thing	
	things[num] = *data;

// mark the new position as dirty
	if (things[num].selected != -1)
	{
		drect = NSMakeRect(data->origin.x - THINGDRAWSIZE/2
		, data->origin.y - THINGDRAWSIZE/2,THINGDRAWSIZE, THINGDRAWSIZE);
		dirtyrect = NSUnionRect (drect, dirtyrect);
	}
	
	return nil;
}


 #pragma mark - SELECTION METHODS


/// select Point
- (void)selectPoint: (int)num
{
	worldpoint_t	*data;
	
	if (num >= numpoints)
	{
		printf ("selectPoint: num >= numpoints\n");
		return;
	}
	data = &points[num];
	if (data->selected == -1)
	{
		printf ("selectPoint: deleted point\n");
		return;
	}
	data->selected = 1;
	[self changePoint: num to:data];
}


/// deselect Point
- (void)deselectPoint: (int)num
{
	worldpoint_t	*data;
	
	if (num >= numpoints)
	{
		printf ("deselectPoint: num >= numpoints\n");
		return;
	}
	data = &points[num];
	if (data->selected == -1)
	{
		printf ("deselectPoint: deleted\n");
		return;
	}
	data->selected = 0;
	[self changePoint: num to:data];
}


/// select Line
- (void)selectLine: (int)num
{
	worldline_t	*data;
	
	if (num >= numlines)
	{
		printf ("selectLine: num >= numlines\n");
		return;
	}
	data = &lines[num];
	if (data->selected == -1)
	{
		printf ("selectLine: deleted\n");
		return;
	}
	data->selected = 1;
	[self changeLine: num to:data];
	
//	[ log_i	msg:"Selecting line!\n" ];
}


/// deselect Line
- (void)deselectLine: (int)num
{
	worldline_t	*data;
	
	if (num >= numlines)
	{
		printf ("deselectLines: num >= numliness\n");
		return;
	}
	data = &lines[num];
	if (data->selected == -1)
	{
		printf ("deselectLine: deleted point\n");
		return;
	}
	data->selected = 0;
	[self changeLine: num to:data];
}


/// select Thing
- (void)selectThing: (int)num
{
	worldthing_t	*data;
	
	if (num >= numthings)
	{
		printf ("selectThing: num >= numthings\n");
		return;
	}
	data = &things[num];
	if (data->selected == -1)
	{
		printf ("selectThing: deleted\n");
		return;
	}
	data->selected = 1;
	[self changeThing: num to:data];
	[thingpanel_i	setThing:data];
}


/// deselect Thing
- (void)deselectThing: (int)num
{
	worldthing_t	*data;
	
	if (num >= numthings)
	{
		printf ("deselectThing: num >= numthings\n");
		return;
	}
	data = &things[num];
	if (data->selected == -1)
	{
		printf ("deselectThing: deleted point\n");
		return;
	}
	data->selected = 0;
	[self changeThing: num to:data];
}



/*
=====================
=
= deselectAll???
=
=====================
*/

- (void)deselectAllPoints
{
	int	p;	
	for (p=0; p<numpoints ; p++)
		if (points[p].selected > 0)
		{
			points[p].selected = 0;
			[self changePoint: p to: &points[p]];
		}
}

- (void)deselectAllLines
{
	int	p;
	for (p=0; p<numlines ; p++)
		if (lines[p].selected >0)
		{
			lines[p].selected = 0;
			[self changeLine: p to: &lines[p]];
		}
}

- (void)deselectAllThings
{
	int	p;
	for (p=0; p<numthings ; p++)
		if (things[p].selected > 0)
		{
			things[p].selected = 0;
			[self changeThing: p to: &things[p]];
		}
}

- (void)deselectAll
{
	[self deselectAllPoints];
	[self deselectAllLines];
	[self deselectAllThings];
}

@end
