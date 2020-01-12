// doomload.m

// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "doombsp.h"


int		linenum = 0;

/*
=================
=
= ReadLine
=
=================
*/

worldline_t *ReadLine (FILE *file)
{
	worldline_t	*line;
#ifdef REDOOMED
	float       p1x, p1y, p2x, p2y;
#else // Original
	NXPoint		*p1, *p2;
#endif
	worldside_t	*s;
	sectordef_t	*e;
	int			i;
	
	line = malloc(sizeof(*line));
	memset (line, 0, sizeof(*line));

#ifdef REDOOMED
	// scan coordinates using local float vars, because NXPoint's x/y members are now CGFloats
	if (fscanf (file,"(%f,%f) to (%f,%f) : %d : %d : %d\n"
		,&p1x, &p1y,&p2x, &p2y,&line->flags
		, &line->special, &line->tag) != 7)
		Error ("Failed ReadLine");

	line->p1 = NSMakePoint(p1x, p1y);
	line->p2 = NSMakePoint(p2x, p2y);
#else // Original
	p1 = &line->p1;
	p2 = &line->p2;
	
	if (fscanf (file,"(%f,%f) to (%f,%f) : %d : %d : %d\n"
		,&p1->x, &p1->y,&p2->x, &p2->y,&line->flags
		, &line->special, &line->tag) != 7)
		Error ("Failed ReadLine");
#endif
	
	for (i=0 ; i<=  ( (line->flags&ML_TWOSIDED) != 0) ; i++)
	{
		s = &line->side[i];	

#ifdef REDOOMED
		// prevent buffer overflows: specify string buffer sizes in *scanf() format strings
		if (fscanf (file,"    %d (%d : %8s / %8s / %8s )\n"
#else // Original
		if (fscanf (file,"    %d (%d : %s / %s / %s )\n"
#endif
			,&s->firstrow, &s->firstcollumn, s->toptexture, s->bottomtexture, s->midtexture) != 5)
			Error ("Failed ReadLine (side)");
		e = &s->sectordef;

#ifdef REDOOMED
		// prevent buffer overflows: specify string buffer sizes in *scanf() format strings
		if (fscanf (file,"    %d : %8s %d : %8s %d %d %d\n"
#else // Original
		if (fscanf (file,"    %d : %s %d : %s %d %d %d\n"
#endif
			,&e->floorheight, e->floorflat, &e->ceilingheight
			,e->ceilingflat,&e->lightlevel, &e->special, &e->tag) != 7)
			Error ("Failed ReadLine (sector)");
		if (!strcmp (e->floorflat,"-"))
			printf ("WARNING: line %i has no sectordef\n",linenum);
	}
	
	linenum++;
	
	return line;
}

/*
=================
=
= ReadThing
=
=================
*/

worldthing_t *ReadThing (FILE *file)
{
	int				x,y;
	worldthing_t	*thing;
	
	thing = malloc(sizeof(*thing));
	memset (thing, 0, sizeof(*thing));

	if (fscanf (file,"(%i,%i, %d) :%d, %d\n"
		,&x, &y, &thing->angle, &thing->type, &thing->options) != 5)
		Error ("Failed ReadThing");

	thing->origin.x = x & -16;
	thing->origin.y = y & -16;
	
	return thing;
}

/*
==================
=
= LineOverlaid
=
= Check to see if the line is colinear and overlapping any previous lines
==================
*/

typedef struct
{
	float	left, right, top, bottom;
} bbox_t;

void BBoxFromPoints (bbox_t *box, NXPoint *p1, NXPoint *p2)
{
	if (p1->x < p2->x)
	{
		box->left = p1->x;
		box->right = p2->x;
	}
	else
	{
		box->left = p2->x;
		box->right = p1->x;
	}
	if (p1->y < p2->y)
	{
		box->bottom = p1->y;
		box->top = p2->y;
	}
	else
	{
		box->bottom = p2->y;
		box->top = p1->y;
	}
}

boolean LineOverlaid (worldline_t *line)
{
	int		j, count;
	worldline_t	*scan;
	divline_t	wl;
	bbox_t		linebox, scanbox;
	
	wl.pt = line->p1;
	wl.dx = line->p2.x - line->p1.x;
	wl.dy = line->p2.y - line->p1.y;

	count = [linestore_i count];
	scan = [linestore_i elementAt:0];
	for (j=0 ; j<count ; j++, scan++)
	{
		if (PointOnSide (&scan->p1, &wl) != -1)
			continue;
		if (PointOnSide (&scan->p2, &wl) != -1)
			continue;
	// line is colinear, see if it overlapps
		BBoxFromPoints (&linebox, &line->p1, &line->p2);
		BBoxFromPoints (&scanbox, &scan->p1, &scan->p2);
				
		if (linebox.right  > scanbox.left && linebox.left < scanbox.right)
			return true;
		if (linebox.bottom < scanbox.top && linebox.top > scanbox.bottom)
			return true;
	}
	return false;
}

/*
===================
=
= LoadDoomMap
=
===================
*/

id	linestore_i, thingstore_i;

void LoadDoomMap (char *mapname)
{
	FILE 		*file;
	int			i, version;
	int			linecount, thingcount;
	worldline_t	*line;
	
	file = fopen (mapname,"r");
	if (!file)
		Error ("LoadDoomMap: couldn't open %s", mapname);
	
	if (!fscanf (file, "WorldServer version %d\n", &version) || version != 4)
		Error ("LoadDoomMap: not a version 4 doom map");
	printf ( "Loading version 4 doom map: %s\n",mapname);
		
//
// read lines
//	
	if (fscanf (file,"\nlines:%d\n",&linecount) != 1)
		Error ("LoadDoomMap: can't read linecount");
	printf ("%i lines\n", linecount);
	linestore_i = [[Storage alloc]
		initCount:		0
		elementSize:	sizeof(worldline_t)
		description:	NULL];

	for (i=0 ; i<linecount ; i++)
	{
		line = ReadLine (file);
		if (line->p1.x == line->p2.x && line->p1.y == line->p2.y)
		{
			printf ("WARNING: line %i is length 0 (removed)\n",i);
			continue;
		}
		if (LineOverlaid (line))
		{
			printf ("WARNING: line %i is overlaid (removed)\n",i);
			continue;
		}
		[linestore_i addElement: line];

#ifdef REDOOMED
		// prevent memory leaks
		free(line);
#endif
	}
		
//
// read things
//
	if (fscanf (file,"\nthings:%d\n",&thingcount) != 1)
		Error ("LoadDoomMap: can't read thingcount");
	printf ( "%i things\n", thingcount);
	thingstore_i = [[Storage alloc]
		initCount:		0
		elementSize:	sizeof(worldthing_t)
		description:	NULL];
		
#ifdef REDOOMED
	// prevent memory leaks: free thing inside loop
	for (i=0 ; i<thingcount ; i++)
	{
		worldthing_t *thing = ReadThing (file);
		[thingstore_i addElement: thing];
		free(thing);
	}
#else // Original
	for (i=0 ; i<thingcount ; i++)
		[thingstore_i addElement: ReadThing (file)];
#endif

	fclose (file);

#ifdef REDOOMED
	// prevent memory leaks
	[linestore_i autorelease];
	[thingstore_i autorelease];
#endif
}

