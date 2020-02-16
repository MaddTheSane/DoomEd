// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

//============================================================================
#ifdef REDOOMED
#   define	DOOMNAME		@"DoomEd"
#else // Original
#   define	DOOMNAME		"DoomEd"
#endif

#define MAXPATCHES	100
/// \c mappatch_t orients a patch inside a \c maptexturedef_t
typedef struct
{
	int		originx;		//!< block origin (allways UL), which has allready accounted
	int		originy;		//!< for the patch's internal origin
	char		patchname[9];
	int		stepdir;		//!< allow flipping of the texture DEBUG: make this a char?
	int		colormap;
} worldpatch_t;

typedef struct
{
	int		WADindex;	//!< which WAD it's from!  (JR 5/28/93 )
	char		name[9];
	BOOL	dirty;		//!< true if changed since last texture file load
	
	int	width;
	int	height;
	int	patchcount;
	worldpatch_t	patches[MAXPATCHES]; //!< [patchcount] drawn back to front into the
} worldtexture_t;

/// a \c sectordef_t describes the features of a sector without listing the lines
typedef struct
{
	int	floorheight, ceilingheight;
	char 	floorflat[9], ceilingflat[9];
	int	lightlevel;
	int	special, tag;	
} sectordef_t;

//============================================================================

@class DoomProject;
@class Wadfile;
@class TextLog;
@class ThermoView;
@class ThingPanel;

extern DoomProject *doomproject_i;
extern Wadfile *wadfile_i;
extern TextLog *log_i;

extern	int	numtextures;
extern	worldtexture_t		*textures;

extern	char	mapwads[1024];		//!< map WAD path
extern	char	bspprogram[1024];	//!< bsp program path
extern	char	bsphost[32];		//!< bsp host machine

//============================================================================

@interface DoomProject : NSObject
{
	BOOL	loaded;
	NSURL	*projectdirectory;
	NSURL	*wadfile;		// WADfile path
	int		nummaps;
	char	mapnames[100][9];
	
	int		texturessize;
	
	IBOutlet NSWindow	*window_i;
	IBOutlet NSTextField	*projectpath_i;
	IBOutlet NSTextField	*wadpath_i;
	IBOutlet NSBrowser		*maps_i;
	IBOutlet ThingPanel		*thingPanel_i;
	IBOutlet id		findPanel_i;
	IBOutlet NSTextField	*mapNameField_i;
	IBOutlet NSTextField	*BSPprogram_i;
	IBOutlet NSTextField	*BSPhost_i;
	IBOutlet NSTextField	*mapwaddir_i;
	
	BOOL	projectdirty;
	BOOL	texturesdirty;
	BOOL	mapdirty;
	
	IBOutlet NSTextField	*thermoTitle_i;
	IBOutlet NSTextField	*thermoMsg_i;
	IBOutlet ThermoView		*thermoView_i;
	IBOutlet NSPanel	*thermoWindow_i;
	
	IBOutlet NSPanel	*printPrefWindow_i;
}


- (instancetype)init;
- (IBAction)displayLog:sender;
@property (readonly) BOOL loaded;
@property (readonly, retain) NSURL *wadfile;
@property (readonly, retain) NSURL *directory;

- (IBAction)menuTarget: sender;
- (IBAction)openProject: sender;
- (IBAction)newProject: sender;
- (IBAction)saveProject: sender;
- (IBAction)reloadProject: sender;
- (IBAction)openMap: sender;
- (IBAction)newMap: sender;
- (IBAction)removeMap: sender;
- (IBAction)printMap:sender;
- (IBAction)printAllMaps:sender;

- (BOOL)loadProject: (char const *)path;
- (BOOL)loadProjectWithFileURL:(NSURL *)path;
- updateTextures;

- (void)updatePanel;

- (int)textureNamed: (char const *)name;

- (BOOL)readTexture: (worldtexture_t *)tex from: (FILE *)file;
- writeTexture: (worldtexture_t *)tex to: (FILE *)file;

- (int)newTexture: (worldtexture_t *)tex;
- (void)changeTexture: (int)num to: (worldtexture_t *)tex;

- saveDoomLumps;
- (IBAction)loadAndSaveAllMaps:sender;
- (IBAction)printStatistics:sender;
- (IBAction)printSingleMapStatistics:sender;
- updateThings;
- updateSectorSpecials;
- updateLineSpecials;
- (void)saveFrame;
- (void)changeWADfile:(NSURL *)string;
- quit;
@property (nonatomic) BOOL projectDirty;
@property (nonatomic) BOOL mapDirty;
- (void)checkDirtyProject;

- (IBAction)printPrefs:sender;
- (IBAction)togglePanel:sender;
- (IBAction)toggleMonsters:sender;
- (IBAction)toggleItems:sender;
- (IBAction)toggleWeapons:sender;

// Thermometer functions
- (void)initThermo:(const char *)title message:(const char *)msg API_DEPRECATED_WITH_REPLACEMENT("-beginThermoWithTitle:message:", macos(10.0, 10.0));
- (void)beginThermoWithTitle:(NSString *)title message:(NSString *)msg;
- (void)updateThermo:(NSInteger)current max:(NSInteger)maximum;
- (void)closeThermo;


//	Map Loading Functions
- beginOpenAllMaps;
- (BOOL)openNextMap;

@end

void IO_Error (const char *error, ...) __printflike(1, 2);
void DE_DrawOutline(NXRect *r);
