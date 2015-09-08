
#import <appkit/appkit.h>

#define	APPDEFAULTS	"ID_doomed"
//	#define NUMCOLORS	9
#define	PREFNAME		@"PrefPanel"

typedef enum
{
	BACK_C = 0,
	GRID_C,
	TILE_C,
	SELECTED_C,
	POINT_C,
	ONESIDED_C,
	TWOSIDED_C,
	AREA_C,
	THING_C,
	SPECIAL_C,
	NUMCOLORS
} ucolor_e;

typedef enum
{
	texturePalette,
	lineInspector,
	lineSpecials,
	errorLog,
	sectorEditor,
	thingPanel,
	sectorSpecials,
	textureEditor,
	NUMOPENUP
} openup_e;

@interface PreferencePanel:NSObject
{
    IBOutlet id	backcolor_i;
    IBOutlet id	gridcolor_i;
    IBOutlet id	tilecolor_i;
    IBOutlet id	selectedcolor_i;
    IBOutlet id	pointcolor_i;
    IBOutlet id	onesidedcolor_i;
    IBOutlet id	twosidedcolor_i;
    IBOutlet id	areacolor_i;
    IBOutlet id	thingcolor_i;
	IBOutlet id	specialcolor_i;
	
	IBOutlet id	launchThingType_i;
	IBOutlet id	projectDefaultPath_i;
	IBOutlet id	openupDefaults_i;
	
    IBOutlet NSWindow *window_i;
	
	id		colorwell[NUMCOLORS];
	NSColor	*color[NUMCOLORS];
	int		launchThingType;
	char	projectPath[128];
}

- (IBAction)menuTarget:sender;
- (IBAction)colorChanged:sender;
- (IBAction)launchThingTypeChanged:sender;
- (IBAction)projectPathChanged:sender;
- (IBAction)openupChanged:sender;

- (void)applicationWillTerminate: (NSNotification *)notification;

//
//	DoomEd accessor methods
//
- (NSColor *)colorFor: (int)ucolor;
- (int)getLaunchThingType;
- (char *)getProjectPath;
- (BOOL)openUponLaunch:(openup_e)type;

@end

extern PreferencePanel *prefpanel_i;

