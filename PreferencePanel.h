
#import <AppKit/AppKit.h>

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
    IBOutlet NSColorWell	*backcolor_i;
    IBOutlet NSColorWell	*gridcolor_i;
    IBOutlet NSColorWell	*tilecolor_i;
    IBOutlet NSColorWell	*selectedcolor_i;
    IBOutlet NSColorWell	*pointcolor_i;
    IBOutlet NSColorWell	*onesidedcolor_i;
    IBOutlet NSColorWell	*twosidedcolor_i;
    IBOutlet NSColorWell	*areacolor_i;
    IBOutlet NSColorWell	*thingcolor_i;
	IBOutlet NSColorWell	*specialcolor_i;
	
	IBOutlet NSTextField	*launchThingType_i;
	IBOutlet NSTextField	*projectDefaultPath_i;
	IBOutlet NSMatrix		*openupDefaults_i;
	
    IBOutlet NSWindow *window_i;
	
	NSColorWell	*colorwell[NUMCOLORS];
	NSMutableArray<NSColor*>		*color;
	int			launchThingType;
	NSString	*projectPath;
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
- (NSColor *)colorFor: (ucolor_e)ucolor;
- (int)getLaunchThingType;
- (const char *)getProjectPath DEPRECATED_MSG_ATTRIBUTE("Use projectPath property instead") NS_RETURNS_INNER_POINTER;
- (BOOL)openUponLaunch:(openup_e)type;
@property (copy) NSString *projectPath;

@end

extern PreferencePanel *prefpanel_i;

