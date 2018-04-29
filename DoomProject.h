#import <AppKit/AppKit.h>
#import "Storage.h"
#import "TextLog.h"
#import "Wadfile.h"

//============================================================================
#define	DOOMNAME		@"DoomEd"
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

@interface DoomProject : NSObject <NSBrowserDelegate>
{
	BOOL	loaded;
	char	projectdirectory[1024];
	char	wadfile[1024];		// WADfile path
	int		nummaps;
	NSString *mapnames[100];

	int		texturessize;
	
	IBOutlet NSWindow		*window_i;
	IBOutlet NSTextField	*projectpath_i;
	IBOutlet NSTextField	*wadpath_i;
	IBOutlet NSBrowser		*maps_i;
	IBOutlet id		thingPanel_i;
	IBOutlet id		findPanel_i;
	IBOutlet NSTextField	*mapNameField_i;
	IBOutlet NSTextField	*BSPprogram_i;
	IBOutlet NSTextField	*BSPhost_i;
	IBOutlet NSTextField	*mapwaddir_i;
	
	BOOL	projectdirty;
	BOOL	texturesdirty;
	BOOL	mapdirty;
	
	IBOutlet id		thermoTitle_i;
	IBOutlet id		thermoMsg_i;
	IBOutlet id		thermoView_i;
	IBOutlet id		thermoWindow_i;
	
	IBOutlet id		printPrefWindow_i;
}


- (instancetype)init;
- (IBAction)displayLog:sender;
@property (readonly, getter=isLoaded) BOOL loaded;
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

- (BOOL)loadProject: (char const *)path;
- (void)updateTextures;

- (void)updatePanel;

- (int)textureNamed: (char const *)name;

- (BOOL)readTexture: (worldtexture_t *)tex from: (FILE *)file;
- (void)writeTexture: (worldtexture_t *)tex to: (FILE *)file;

- (int)newTexture: (worldtexture_t *)tex;
- (void)changeTexture: (int)num to: (worldtexture_t *)tex;

- (void)saveDoomLumps;
- (IBAction)loadAndSaveAllMaps:sender;
- (IBAction)printStatistics:sender;
- (IBAction)printSingleMapStatistics:sender;
- (void)updateThings;
- (void)updateSectorSpecials;
- (void)updateLineSpecials;
- (void)saveFrame;
- (void)changeWADfile:(char *)string;
- (void)quit;
- (void)setDirtyProject:(BOOL)truth DEPRECATED_MSG_ATTRIBUTE("Use setProjectDirty: instead");
- (void)setDirtyMap:(BOOL)truth DEPRECATED_MSG_ATTRIBUTE("Use setMapDirty: instead");
- (BOOL)projectDirty DEPRECATED_MSG_ATTRIBUTE("Use projectDirty property instead");
- (BOOL)mapDirty DEPRECATED_MSG_ATTRIBUTE("Use mapDirty property instead");
@property (getter=isProjectDirty) BOOL projectDirty;
@property (nonatomic, getter=isMapDirty) BOOL mapDirty;
- (void)checkDirtyProject;

- (IBAction)printPrefs:sender;
- (IBAction)togglePanel:sender;
- (IBAction)toggleMonsters:sender;
- (IBAction)toggleItems:sender;
- (IBAction)toggleWeapons:sender;

// Thermometer functions
- (void)initThermo:(NSString *)title message:(NSString *)msg;
- (void)updateThermo:(int)current max:(int)maximum;
- (void)closeThermo;


//	Map Loading Functions
- (void)beginOpenAllMaps;
- (BOOL)openNextMap;

@end

void IO_Error (char *error, ...);
void DE_DrawOutline(NSRect *r);

//============================================================================

extern DoomProject *doomproject_i;
extern Wadfile *wadfile_i;
extern TextLog *log_i;

extern int numtextures;
extern worldtexture_t *textures;

extern char mapwads[1024];		// map WAD path
extern char bspprogram[1024];	// bsp program path
extern char bsphost[32];		// bsp host machine

