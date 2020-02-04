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
// mappatch_t orients a patch inside a maptexturedef_t
typedef struct
{
	int		originx;		// block origin (allways UL), which has allready accounted
	int		originy;		// for the patch's internal origin
	char		patchname[9];
	int		stepdir;		// allow flipping of the texture DEBUG: make this a char?
	int		colormap;
} worldpatch_t;

typedef struct
{
	int		WADindex;	// which WAD it's from!  (JR 5/28/93 )
	char		name[9];
	BOOL	dirty;		// true if changed since last texture file load
	
	int	width;
	int	height;
	int	patchcount;
	worldpatch_t	patches[MAXPATCHES]; // [patchcount] drawn back to front into the
} worldtexture_t;

// a sectordef_t describes the features of a sector without listing the lines
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

extern DoomProject *doomproject_i;
extern Wadfile *wadfile_i;
extern TextLog *log_i;

extern	int	numtextures;
extern	worldtexture_t		*textures;

extern	char	mapwads[1024];		// map WAD path
extern	char	bspprogram[1024];	// bsp program path
extern	char	bsphost[32];		// bsp host machine

//============================================================================

@interface DoomProject : Object
{
	BOOL	loaded;
	char	projectdirectory[1024];
	char	wadfile[1024];		// WADfile path
	int		nummaps;
	char	mapnames[100][9];
	
	int		texturessize;
	
	IBOutlet NSWindow	*window_i;
	id		projectpath_i;
	id		wadpath_i;
	id		maps_i;
	IBOutlet id		thingPanel_i;
	id		findPanel_i;
	id		mapNameField_i;
	id		BSPprogram_i;
	id		BSPhost_i;
	id		mapwaddir_i;
	
	BOOL	projectdirty;
	BOOL	texturesdirty;
	BOOL	mapdirty;
	
	IBOutlet NSTextField	*thermoTitle_i;
	IBOutlet NSTextField	*thermoMsg_i;
	IBOutlet id		thermoView_i;
	IBOutlet NSPanel	*thermoWindow_i;
	
	IBOutlet NSWindow	*printPrefWindow_i;
}


- (instancetype)init;
- (IBAction)displayLog:sender;
@property (readonly) BOOL loaded;
- (char *)wadfile;
- (char const *)directory;

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

- loadProject: (char const *)path;
- (BOOL)loadProjectWithFileURL:(NSURL *)path;
- updateTextures;

- updatePanel;

- (int)textureNamed: (char const *)name;

- (BOOL)readTexture: (worldtexture_t *)tex from: (FILE *)file;
- writeTexture: (worldtexture_t *)tex to: (FILE *)file;

- (int)newTexture: (worldtexture_t *)tex;
- changeTexture: (int)num to: (worldtexture_t *)tex;

- saveDoomLumps;
- (IBAction)loadAndSaveAllMaps:sender;
- (IBAction)printStatistics:sender;
- (IBAction)printSingleMapStatistics:sender;
- updateThings;
- updateSectorSpecials;
- updateLineSpecials;
- (void)saveFrame;
- changeWADfile:(char *)string;
- quit;
- setDirtyProject:(BOOL)truth API_DEPRECATED_WITH_REPLACEMENT("-setProjectDirty:", macos(10.0, 10.0));
- setDirtyMap:(BOOL)truth API_DEPRECATED_WITH_REPLACEMENT("-setMapDirty:", macos(10.0, 10.0));
@property (nonatomic) BOOL projectDirty;
@property (nonatomic) BOOL mapDirty;
- (void)checkDirtyProject;

- (IBAction)printPrefs:sender;
- (IBAction)togglePanel:sender;
- (IBAction)toggleMonsters:sender;
- (IBAction)toggleItems:sender;
- (IBAction)toggleWeapons:sender;

// Thermometer functions
- initThermo:(char *)title message:(char *)msg;
- updateThermo:(int)current max:(int)maximum;
- closeThermo;


//	Map Loading Functions
- beginOpenAllMaps;
- (BOOL)openNextMap;

@end

void IO_Error (char *error, ...) __printflike(1, 2);
void DE_DrawOutline(NXRect *r);
