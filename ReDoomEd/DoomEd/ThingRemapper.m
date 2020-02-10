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

- (void)addToList:(char *)orgname to:(char *)newname;
{
	[remapper_i	addToList:orgname to:newname];
}

//===================================================================
//
//	Delegate methods
//
//===================================================================
- (const char *)getOriginalName
{
	ThingPanelListObject	*t;
	
	t = [thingpanel_i	getCurrentThingData];
	if (t == NULL)
		return NULL;
	return t.name.UTF8String;
}

- (const char *)getNewName
{
	ThingPanelListObject	*t;
	
	t = [thingpanel_i	getCurrentThingData];
	if (t == NULL)
		return NULL;
	return t.name.UTF8String;
}

- (int)doRemap:(char *)oldname to:(char *)newname
{
	int	i, thingnum,oldnum,newnum;
	ThingPanelListObject	*t;
	
	t = [thingpanel_i	getThingData:[thingpanel_i	findThing:@(oldname)]];
	oldnum = t.value;
	t = [thingpanel_i	getThingData:[thingpanel_i	findThing:@(newname)]];
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
