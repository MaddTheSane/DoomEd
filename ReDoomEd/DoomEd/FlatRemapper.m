// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"EditWorld.h"
#import	"SectorEditor.h"
#import	"FlatRemapper.h"

id	flatRemapper_i;

@implementation FlatRemapper
//===================================================================
//
//	REMAP FLATS IN MAP
//
//===================================================================
- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	flatRemapper_i = self;
	
	remapper_i = [ [ Remapper	alloc ]
				setFrameName:"FlatRemapper"
				setPanelTitle:"Flat Remapper"
				setBrowserTitle:"List of flats to be remapped"
				setRemapString:"Flat"
				setDelegate:self ];
	return self;
}

//===================================================================
//
//	Bring up panel
//
//===================================================================
- menuTarget:sender
{
	[remapper_i	showPanel];
	return self;
}

- addToList:(char *)orgname to:(char *)newname;
{
	[remapper_i	addToList:orgname to:newname];
	return self;
}

//===================================================================
//
//	Delegate methods
//
//===================================================================
- (char *)getOriginalName
{
	return [sectorEdit_i	flatName:[sectorEdit_i getCurrentFlat] ];
}

- (char *)getNewName
{
	return [sectorEdit_i	flatName:[sectorEdit_i getCurrentFlat] ];
}

- (int)doRemap:(char *)oldname to:(char *)newname
{
	int		i;
	int		linenum;
	int		flag;
	
#ifdef REDOOMED
	// prevent buffer overflows: before calling strcpy(), clip the source string to
	// the destination strings' (sectordef_t's floorflat & ceilingflat) buffer size
	macroRDE_ClipCStringLocallyForBufferSize(newname,
	                                        macroRDE_SizeOfTypeMember(sectordef_t, floorflat));
#endif

	linenum = 0;
	for (i = 0;i < numlines; i++)
	{
		flag = 0;
		// SIDE 0
		if (!strcasecmp ( oldname,lines[i].side[0].ends.floorflat))
		{
			strcpy(lines[i].side[0].ends.floorflat, newname );
			flag++;
		}
		if (!strcasecmp( oldname,lines[i].side[0].ends.ceilingflat))
		{
			strcpy(lines[i].side[0].ends.ceilingflat, newname );
			flag++;
		}

		// SIDE 1
		if (!strcasecmp ( oldname,lines[i].side[1].ends.floorflat))
		{
			strcpy(lines[i].side[1].ends.floorflat, newname );
			flag++;
		}
		if (!strcasecmp( oldname,lines[i].side[1].ends.ceilingflat))
		{
			strcpy(lines[i].side[1].ends.ceilingflat, newname );
			flag++;
		}
		
		if (flag)
		{
			printf("Remapped flat %s to %s.\n",oldname,newname);
			linenum++;
		}
	}
	
	
	return linenum;
}

- finishUp
{
	return self;
}

@end
