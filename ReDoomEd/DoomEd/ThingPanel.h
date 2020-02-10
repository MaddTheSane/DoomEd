// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

#import 	"DoomProject.h"
#import		"EditWorld.h"

@class Storage;
@class ThingPanel;
extern ThingPanel *thingpanel_i;

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

@interface ThingPanel:NSObject <NSWindowDelegate>
{
	IBOutlet NSForm	*fields_i;
 	IBOutlet NSPanel *window_i;
	IBOutlet NSButton *addButton_i;
	IBOutlet NSButton	*updateButton_i;
	IBOutlet NSTextField *nameField_i;
	IBOutlet NSBrowser *thingBrowser_i;
	IBOutlet NSColorWell *thingColor_i;
	IBOutlet NSMatrix *thingAngle_i;
	Storage	*masterList_i;
	IBOutlet NSTextField	*iconField_i;
	IBOutlet NSButton	*ambush_i;		// switch
	IBOutlet NSButton	*network_i;		// switch
	IBOutlet NSMatrix	*difficulty_i;	// switch matrix
	IBOutlet NSMatrix	*diffDisplay_i;	// radio matrix
	IBOutlet NSTextField	*count_i;		// display count
	
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
- (IBAction)updateThingData:sender;
- (void)sortThings;
- (IBAction)setAngle:sender;
- (NXColor)getThingColor:(int)type;
- (void)fillThingData:(thinglist_t *)thing;
- (void)fillDataFromThing:(thinglist_t *)thing;
- (void)fillAllDataFromThing:(thinglist_t *)thing;
- (IBAction)addThing:sender;
- (NSInteger)findThing:(char *)string;
- (thinglist_t *)getThingData:(NSInteger)index;
- (IBAction)chooseThing:sender;
- (IBAction)confirmCorrectNameEntry:sender;
- (void)getThing:(worldthing_t *)thing;
- (void)setThing:(worldthing_t *)thing;
- (NSInteger)searchForThingType:(int)type;
- (IBAction)suggestNewType:sender;
- scrollToItem:(NSInteger)which;
@property (readonly, retain) Storage *thingList;

- (IBAction)verifyIconName:sender;
- (IBAction)assignIcon:sender;
- (IBAction)unlinkIcon:sender;
- (void)selectThingWithIcon:(const char *)name;

- (thinglist_t *)getCurrentThingData;
- (void)countCurrentThings;


- (BOOL) readThing:(thinglist_t *)thing	from:(FILE *)stream;
- (void)writeThing:(thinglist_t *)thing	from:(FILE *)stream;
- (void)updateThingsDSP:(FILE *)stream;

@end
