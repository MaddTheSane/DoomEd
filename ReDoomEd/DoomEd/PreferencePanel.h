// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

extern	id	prefpanel_i;

#define	APPDEFAULTS	"ID_doomed"
//	#define NUMCOLORS	9

#ifdef REDOOMED
#   define	PREFNAME		@"PrefPanel"
#else // Original
#   define	PREFNAME		"PrefPanel"
#endif

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

@interface PreferencePanel:Object
{
    id	backcolor_i;
    id	gridcolor_i;
    id	tilecolor_i;
    id	selectedcolor_i;
    id	pointcolor_i;
    id	onesidedcolor_i;
    id	twosidedcolor_i;
    id	areacolor_i;
    id	thingcolor_i;
	id	specialcolor_i;
	
	id	launchThingType_i;
	id	projectDefaultPath_i;
	id	openupDefaults_i;
	
    id	window_i;
	
	id		colorwell[NUMCOLORS];
	NXColor	color[NUMCOLORS];
	int		launchThingType;
#ifdef REDOOMED
	// increase buffer size to allow max-length filepaths
	char	projectPath[RDE_MAX_FILEPATH_LENGTH+1];
#else // Original
	char	projectPath[128];
#endif
}

- menuTarget:sender;
- colorChanged:sender;
- launchThingTypeChanged:sender;
- projectPathChanged:sender;
- openupChanged:sender;

- appWillTerminate: sender;

//
//	DoomEd accessor methods
//
- (NXColor)colorFor: (int)ucolor;
- (int)getLaunchThingType;
- (char *)getProjectPath;
- (BOOL)openUponLaunch:(openup_e)type;

@end