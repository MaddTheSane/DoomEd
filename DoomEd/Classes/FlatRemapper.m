#import	"EditWorld.h"
#import	"SectorEditor.h"
#import	"FlatRemapper.h"

FlatRemapper *flatRemapper_i;

@implementation FlatRemapper
//===================================================================
//
//	REMAP FLATS IN MAP
//
//===================================================================
- init
{
	if (self = [super init]) {
	flatRemapper_i = self;

	[self
		setFrameName: @"FlatRemapper"
		setPanelTitle: @"Flat Remapper"
		setBrowserTitle: @"List of flats to be remapped"
		setRemapString: @"Flat"
		setDelegate: self
	];
	}
	return self;
}

//===================================================================
//
//	Bring up panel
//
//===================================================================
- (IBAction)menuTarget:sender
{
	[self	showPanel];
}

//===================================================================
//
//	Delegate methods
//
//===================================================================
- (NSString *)getOriginalName
{
	return [sectorEdit_i flatName:[sectorEdit_i getCurrentFlat] ];
}

- (NSString *)getNewName
{
	return [sectorEdit_i flatName:[sectorEdit_i getCurrentFlat] ];
}

- (NSInteger)doRemap: (NSString *) oldn to: (NSString *) newn
{
	const char *oldname, *newname;
	int i;
	int linenum;
	BOOL flag;

	oldname = [oldn UTF8String];
	newname = [newn UTF8String];

	linenum = 0;
	for (i = 0;i < numlines; i++)
	{
		flag = NO;
		// SIDE 0
		if (!strcasecmp ( oldname,lines[i].side[0].ends.floorflat))
		{
			strcpy(lines[i].side[0].ends.floorflat, newname );
			flag = YES;
		}
		if (!strcasecmp( oldname,lines[i].side[0].ends.ceilingflat))
		{
			strcpy(lines[i].side[0].ends.ceilingflat, newname );
			flag = YES;
		}

		// SIDE 1
		if (!strcasecmp ( oldname,lines[i].side[1].ends.floorflat))
		{
			strcpy(lines[i].side[1].ends.floorflat, newname );
			flag = YES;
		}
		if (!strcasecmp( oldname,lines[i].side[1].ends.ceilingflat))
		{
			strcpy(lines[i].side[1].ends.ceilingflat, newname );
			flag = YES;
		}
		
		if (flag)
		{
			printf("Remapped flat %s to %s.\n",oldname,newname);
			linenum++;
		}
	}
	
	
	return linenum;
}

- (void)finishUp
{
}

@end
