// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

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
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	flatRemapper_i = self;
	
	remapper_i = [[Remapper alloc] init];
	[remapper_i setFrameName:@"FlatRemapper"
				  panelTitle:@"Flat Remapper"
				browserTitle:@"List of flats to be remapped"
				 remapString:@"Flat"
					delegate:self];
	return self;
}

//===================================================================
//
//	Bring up panel
//
//===================================================================
- (IBAction)menuTarget:sender
{
	[remapper_i	showPanel];
}

- (void)addToListFromName:(NSString *)orgname toName:(NSString *)newname
{
	[remapper_i addToListFromName:orgname toName:newname];
}

//===================================================================
//
//	Delegate methods
//
//===================================================================
- (NSString *)originalName
{
	const char *orig = [sectorEdit_i flatName:[sectorEdit_i currentFlat]];
	if (!orig) {
		return nil;
	}
	return @(orig);
}

- (NSString *)newName
{
	const char *orig = [sectorEdit_i flatName:[sectorEdit_i currentFlat]];
	if (!orig) {
		return nil;
	}
	return @(orig);
}

- (int)doRemapFromName:(NSString *)oldname toName:(NSString *)newname
{
	int		i;
	int		linenum;
	int		flag;
	const char *oldStr = oldname.UTF8String;
	const char *newStr = newname.UTF8String;
	
	linenum = 0;
	for (i = 0;i < numlines; i++)
	{
		flag = 0;
		// SIDE 0
		if (!strncasecmp(oldStr, lines[i].side[0].ends.floorflat, sizeof(lines[i].side[0].ends.floorflat)))
		{
			strncpy(lines[i].side[0].ends.floorflat, newStr, sizeof(lines[i].side[0].ends.floorflat));
			flag++;
		}
		if (!strncasecmp(oldStr, lines[i].side[0].ends.ceilingflat, sizeof(lines[i].side[0].ends.ceilingflat)))
		{
			strncpy(lines[i].side[0].ends.ceilingflat, newStr, sizeof(lines[i].side[0].ends.ceilingflat));
			flag++;
		}

		// SIDE 1
		if (!strncasecmp(oldStr, lines[i].side[1].ends.floorflat, sizeof(lines[i].side[1].ends.floorflat)))
		{
			strncpy(lines[i].side[1].ends.floorflat, newStr, sizeof(lines[i].side[1].ends.floorflat));
			flag++;
		}
		if (!strncasecmp(oldStr, lines[i].side[1].ends.ceilingflat, sizeof(lines[i].side[1].ends.ceilingflat)))
		{
			strncpy(lines[i].side[1].ends.ceilingflat, newStr, sizeof(lines[i].side[1].ends.ceilingflat));
			flag++;
		}
		
		if (flag)
		{
			printf("Remapped flat %s to %s.\n", oldStr, newStr);
			linenum++;
		}
	}
	
	
	return linenum;
}

- (void)finishUp
{
}

@end
