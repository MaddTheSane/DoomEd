// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"EditWorld.h"
#import	"ThingPanel.h"
#import	"ThingRemapper.h"

ThingRemapper *thingRemapper_i;

@implementation ThingRemapper
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

	thingRemapper_i = self;
	
	remapper_i = [[Remapper alloc] init];
	[remapper_i setFrameName:@"ThingRemapper"
				  panelTitle:@"Thing Remapper"
				browserTitle:@"List of things to be remapped"
				 remapString:@"Thing"
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

- (void)addToListFromName:(NSString *)orgname toName:(NSString *)newname;
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
	ThingPanelListObject	*t;
	
	t = [thingpanel_i	currentThingData];
	if (t == NULL)
		return NULL;
	return t.name;
}

- (NSString *)newName
{
	ThingPanelListObject	*t;
	
	t = [thingpanel_i	currentThingData];
	if (t == NULL)
		return NULL;
	return t.name;
}

- (int)doRemapFromName:(NSString *)oldname toName:(NSString *)newname
{
	int	i, thingnum,oldnum,newnum;
	ThingPanelListObject	*t;
	
	t = [thingpanel_i	getThingData:[thingpanel_i	findThing:oldname]];
	oldnum = t.value;
	t = [thingpanel_i	getThingData:[thingpanel_i	findThing:newname]];
	newnum = t.value;
	thingnum = 0;
	
	for (i = 0;i < numthings; i++)
	{
		if (things[i].type == oldnum)
		{
			things[i].type = newnum;
			thingnum++;
		}
	}
	
	return thingnum;
}

- (void)finishUp
{
	[editworld_i	redrawWindows];
}

@end
