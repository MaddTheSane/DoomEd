// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@class PreferencePanel;
extern PreferencePanel *prefpanel_i;

#define	APPDEFAULTS	"ID_doomed"
//	#define NUMCOLORS	9

#ifdef REDOOMED
#   define	PREFNAME		@"PrefPanel"
#else // Original
#   define	PREFNAME		"PrefPanel"
#endif

typedef NS_ENUM(int, ucolor_e)
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
};

typedef NS_ENUM(int, openup_e)
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
};

#if 0
@interface PreferencePanel:NSObject
{
	@private
    IBOutlet NSColorWell *backcolor_i;
    IBOutlet NSColorWell *gridcolor_i;
    IBOutlet NSColorWell *tilecolor_i;
    IBOutlet NSColorWell *selectedcolor_i;
    IBOutlet NSColorWell *pointcolor_i;
    IBOutlet NSColorWell *onesidedcolor_i;
    IBOutlet NSColorWell *twosidedcolor_i;
    IBOutlet NSColorWell *areacolor_i;
    IBOutlet NSColorWell *thingcolor_i;
	IBOutlet NSColorWell *specialcolor_i;
	
	IBOutlet NSTextField *launchThingType_i;
	IBOutlet NSTextField *projectDefaultPath_i;
	IBOutlet NSMatrix	*openupDefaults_i;
	
    IBOutlet NSPanel *window_i;
	
	NSColorWell *colorwell[NUMCOLORS];
	NSColor	*color[NUMCOLORS];
	int		launchThingType;
#ifdef REDOOMED
	// increase buffer size to allow max-length filepaths
	char	projectPath[RDE_MAX_FILEPATH_LENGTH+1];
#else // Original
	char	projectPath[128];
#endif
}

- (IBAction)menuTarget:sender;
- (IBAction)colorChanged:sender;
- (IBAction)launchThingTypeChanged:sender;
- (IBAction)projectPathChanged:sender;
- (IBAction)openupChanged:sender;

- appWillTerminate: sender;

//
//	DoomEd accessor methods
//
- (NXColor)colorFor: (int)ucolor API_DEPRECATED_WITH_REPLACEMENT("-colorForColor:", macos(10.0, 10.0));
- (NSColor*)colorForColor: (ucolor_e)ucolor;
- (const char *)getProjectPath;
- (BOOL)openUponLaunch:(openup_e)type;
@property (readonly) int launchThingType;

@end
#endif
