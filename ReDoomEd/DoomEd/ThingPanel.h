// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

#import 	"DoomProject.h"
#import		"EditWorld.h"

@class ThingPanel;
extern	ThingPanel	*thingpanel_i;

typedef struct
{
	char		name[32];
	char		iconname[9];
	NXColor	color;
	int		value, option,angle;
} thinglist_t;

#ifdef REDOOMED
#   define	THINGNAME	@"ThingInspector"
#else // Original
#   define	THINGNAME	"ThingInspector"
#endif

#define	DIFF_EASY	0
#define DIFF_NORMAL	1
#define DIFF_HARD	2
#define DIFF_ALL	3

@interface ThingPanel:Object
{
	IBOutlet NSForm	*fields_i;
 	IBOutlet NSWindow	*window_i;
	id	addButton_i;
	id	updateButton_i;
	id	nameField_i;
	id	thingBrowser_i;
	id	thingColor_i;
	id	thingAngle_i;
	id	masterList_i;
	IBOutlet NSTextField	*iconField_i;
	IBOutlet NSButton	*ambush_i;		// switch
	IBOutlet NSButton	*network_i;		// switch
	IBOutlet NSMatrix	*difficulty_i;	// switch matrix
	IBOutlet NSMatrix	*diffDisplay_i;	// radio matrix
	id	count_i;		// display count
	
	int	diffDisplay;
	
	worldthing_t	basething, oldthing;
}

- (IBAction)changeDifficultyDisplay:sender;
- (int)getDifficultyDisplay;
- emptyThingList;
- pgmTarget;
- (IBAction)menuTarget:sender;
- saveFrame;
- (IBAction)formTarget: sender;
- updateInspector: (BOOL)force;
- updateThingInspector;
- (IBAction)updateThingData:sender;
- sortThings;
- (IBAction)setAngle:sender;
- (NXColor)getThingColor:(int)type;
- fillThingData:(thinglist_t *)thing;
- fillDataFromThing:(thinglist_t *)thing;
- fillAllDataFromThing:(thinglist_t *)thing;
- (IBAction)addThing:sender;
- (int)findThing:(char *)string;
- (thinglist_t *)getThingData:(int)index;
- (IBAction)chooseThing:sender;
- (IBAction)confirmCorrectNameEntry:sender;
- getThing:(worldthing_t	*)thing;
- setThing:(worldthing_t *)thing;
- (int)searchForThingType:(int)type;
- (IBAction)suggestNewType:sender;
- scrollToItem:(int)which;
- getThingList;

- (IBAction)verifyIconName:sender;
- (IBAction)assignIcon:sender;
- (IBAction)unlinkIcon:sender;
- selectThingWithIcon:(char *)name;

- (thinglist_t *)getCurrentThingData;
- currentThingCount API_DEPRECATED_WITH_REPLACEMENT("-countCurrentThings", macos(10.0, 10.0));
- (void)countCurrentThings;


- (BOOL) readThing:(thinglist_t *)thing	from:(FILE *)stream;
- writeThing:(thinglist_t *)thing	from:(FILE *)stream;
- updateThingsDSP:(FILE *)stream;

@end
