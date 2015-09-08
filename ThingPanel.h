#import "Storage.h"

#import <appkit/appkit.h>
#import 	"DoomProject.h"
#import		"EditWorld.h"

extern	id	thingpanel_i;

typedef struct
{
	char		name[32];
	char		iconname[9];
	NSColor	*color;
	int		value, option,angle;
} thinglist_t;

#define	THINGNAME	@"ThingInspector"

#define	DIFF_EASY	0
#define DIFF_NORMAL	1
#define DIFF_HARD	2
#define DIFF_ALL	3

@interface ThingPanel:NSObject
{
	IBOutlet id	fields_i;
 	IBOutlet id	window_i;
	IBOutlet id	addButton_i;
	IBOutlet id	updateButton_i;
	IBOutlet id	nameField_i;
	IBOutlet id	thingBrowser_i;
	IBOutlet id	thingColor_i;
	IBOutlet id	thingAngle_i;
	CompatibleStorage *masterList_i;
	IBOutlet id	iconField_i;
	IBOutlet id	ambush_i;		// switch
	IBOutlet id	network_i;		// switch
	IBOutlet id	difficulty_i;	// switch matrix
	IBOutlet id	diffDisplay_i;	// radio matrix
	IBOutlet id	count_i;		// display count
	
	int	diffDisplay;
	
	worldthing_t	basething, oldthing;
}

- (IBAction)changeDifficultyDisplay:sender;
- (int)getDifficultyDisplay;
- (void)emptyThingList;
- (void)pgmTarget;
- (IBAction)menuTarget:sender;
- (void)saveFrame;
- (IBAction)formTarget: sender;
- (void)updateInspector: (BOOL)force;
- (void)updateThingInspector;
- (void)updateThingData:sender;
- (void)sortThings;
- (IBAction)setAngle:sender;
- (NSColor *)getThingColor:(int)type;
- (void)fillThingData:(thinglist_t *)thing;
- (void)fillDataFromThing:(thinglist_t *)thing;
- (void)fillAllDataFromThing:(thinglist_t *)thing;
- (IBAction)addThing:sender;
- (int)findThing:(const char *)string;
- (thinglist_t *)getThingData:(int)index;
- (IBAction)chooseThing:sender;
- (IBAction)confirmCorrectNameEntry:sender;
- (void)getThing:(worldthing_t	*)thing;
- (void)setThing:(worldthing_t *)thing;
- (int)searchForThingType:(int)type;
- (IBAction)suggestNewType:sender;
- (void)scrollToItem:(int)which;
- (void)getThingList;

- (IBAction)verifyIconName:sender;
- (IBAction)assignIcon:sender;
- (IBAction)unlinkIcon:sender;
- (void)selectThingWithIcon:(char *)name;

- (thinglist_t *)getCurrentThingData;
- (void)currentThingCount;

- (BOOL) readThing:(thinglist_t *)thing	from:(FILE *)stream;
- (void)writeThing:(thinglist_t *)thing	from:(FILE *)stream;
- (void)updateThingsDSP:(FILE *)stream;

@end
