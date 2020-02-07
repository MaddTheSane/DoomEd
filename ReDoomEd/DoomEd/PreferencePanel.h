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
