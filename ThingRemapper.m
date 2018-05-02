#import	"EditWorld.h"
#import	"ThingPanel.h"
#import	"ThingRemapper.h"

id	thingRemapper_i;

@implementation ThingRemapper
//===================================================================
//
//	REMAP FLATS IN MAP
//
//===================================================================
- init
{
	if (self = [super init]) {
	thingRemapper_i = self;

	remapper_i = [[Remapper alloc] init];
	[remapper_i
		setFrameName: @"ThingRemapper"
		setPanelTitle: @"Thing Remapper"
		setBrowserTitle: @"List of things to be remapped"
		setRemapString: @"Thing"
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
	[remapper_i	showPanel];
}

- (void)addToList: (NSString *) orgname to: (NSString *) newname;
{
	[remapper_i addToList:orgname to:newname];
}

//===================================================================
//
//	Delegate methods
//
//===================================================================
- (NSString *)getOriginalName
{
	thinglist_t t;

	if ([thingpanel_i getCurrentThingData:&t])
		return NULL;
	return [NSString stringWithUTF8String: t.name];
}

- (NSString *)getNewName
{
	return [self getOriginalName];
}

- (int)doRemap: (NSString *) oldn to: (NSString *) newn
{
	const char *oldname, *newname;
	int	i, thingnum,oldnum,newnum;
	thinglist_t	*t;

	oldname = [oldn UTF8String];
	newname = [newn UTF8String];

	t = [thingpanel_i getThingData:[thingpanel_i findThing:oldname]];
	oldnum = t->value;
	t = [thingpanel_i getThingData:[thingpanel_i findThing:newname]];
	newnum = t->value;
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
