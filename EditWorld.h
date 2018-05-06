#import <AppKit/AppKit.h>
#import "Storage.h"
#import "DoomProject.h"

#define	WORLDNAME	@"EditWorld"

typedef struct worldpoint_s
{
	int	selected;		//!< context that owns the point, 0 if unselected, or -1 if deleted
	int	refcount;		//!< when 0, remove it

	NSPoint	pt;
} worldpoint_t;

typedef struct worldside_s
{
	int		flags;	
	int		firstcollumn;
	char		toptexture[9];
	char		bottomtexture[9];
	char		midtexture[9];
	sectordef_t	ends;				//!< on the viewer's side
	int		sector;					//!< only used when saving doom map
} worldside_t;

typedef struct worldline_s
{
	int	selected;			//!< 0 if unselected, -1 if deleted, 1 if selected, 2 if back side selected
	
	int	p1, p2;
	int	special, tag;
	int	flags;
	
	worldside_t	side[2];

	NSPoint	mid;
	NSPoint	norm;
} worldline_t;

#define	ML_BLOCKMOVE			1
#define	ML_TWOSIDED			4	// backside will not be present at all if not two sided

typedef struct worldthing_s
{
	int	selected;		//!< 0 if unselected, -1 if deleted, 1 if selected

	NSPoint	origin;
	int	angle;
	int	type;
	int	options;
	int	area;
} worldthing_t;

typedef struct worldsector_s
{
	sectordef_t	s;
	CompatibleStorage *lines;	//!< storage object of line numbers
} worldsector_t;

typedef struct copyline_s
{
	worldline_t	l;
	NSPoint		p1,p2;
} copyline_t;

//===========================================================================

@interface EditWorld : NSObject<NSWindowDelegate>
{
	BOOL	loaded;
	
	int		pointssize, linessize, thingssize, texturessize;	// array size >= numvalid
	BOOL	dirty, dirtypoints;		// set whenever the map is changed FIXME
	NSRect	bounds;
	BOOL	boundsdirty;
	NSString *pathname;
	NSRect	dirtyrect;
	NSMutableArray *windowlist_i;	// all windows that display this world

	CompatibleStorage *copyThings_i;		// cut/copy/paste info
	CompatibleStorage *copyLines_i;
	NSPoint	copyCoord;
	int		copyLoaded;
	NSSound *saveSound;				// Sound instance
}

- (void)applicationWillTerminate: (NSNotification *)notification;
- (BOOL)loadWorldFile: (NSString *)path;
- (IBAction)saveDoomEdMapBSP:sender;

- (BOOL)loaded;
- (BOOL)dirty;
- (BOOL)dirtyPoints;

- (void)closeWorld;

//
// menu targets
//
- (IBAction)newWindow:sender;
- (IBAction)saveWorld:sender;
- (IBAction)print:sender;

//
// selection operations
//

- (IBAction)cut: sender;
- (IBAction)copy: sender;
- (IBAction)paste: sender;
- (IBAction)delete: sender;
- (IBAction)flipSelectedLines: sender;
- (IBAction)fusePoints: sender;
- (IBAction)seperatePoints: sender;

//
// dealing with map windows
//
- (void) updateWindows;
- (void)addToDirtyRect: (int)p1 : (int)p2;
- (void)updateLineNormal:(int) num;
- (void)redrawWindows;
- (NSWindow*)getMainWindow;	// returns window id

//
// get info
//
- (NSRect) getBounds;

//
// change info
//
- (void)selectPoint: (int)num;
- (void)deselectPoint: (int)num;
- (void)selectLine: (int)num;
- (void)deselectLine: (int)num;
- (void)selectThing: (int)num;
- (void)deselectThing: (int)num;
- (void)deselectAllPoints;
- (void)deselectAllLines;
- (void)deselectAllThings;
- (void)deselectAll;


- (int)allocatePoint: (NSPoint *)pt;
- (int)newPoint: (NSPoint *)pt;
- (int)newLine: (worldline_t *)line from: (NSPoint *)p1 to:(NSPoint *)p2;
- (int)newThing: (worldthing_t *)thing;

- (void)changePoint: (int)p to: (worldpoint_t *)data;
- (void)changeLine: (int)p to: (worldline_t *)data;
- (void)changeThing: (int)p to: (worldthing_t *)data;


//
// Cut/copy/paste stuff
//
- (void)storeCopies;
- (void)copyDeselect;
- (NSPoint)findCopyCenter;
- (int)findMin:(int)num0	:(int)num1;
- (int)findMax:(int)num0	:(int)num1;
@end


//
// EWLoadSave catagory
//
@interface EditWorld (EWLoadSave)

- (BOOL)readLine: (NSPoint *)p1 : (NSPoint *)p2 : (worldline_t *)line from: (FILE *)file;
- (void)writeLine: (worldline_t *)line to: (FILE *)file;
- (BOOL)readThing: (worldthing_t *)thing from: (FILE *)file;
- (void)writeThing: (worldthing_t *)thing to: (FILE *)file;

- (BOOL)loadV4File: (FILE *)file;
- (BOOL)saveFile: (FILE *)file;

@end

//
// EWDoomSave catagory
//
@interface EditWorld (EWDoomSave)

- (BOOL)saveDoomMap;

@end

//===========================================================================
// GLOBAL variables

extern EditWorld *editworld_i;

extern int numpoints, numlines, numthings;

extern worldpoint_t *points;
extern worldline_t  *lines;
extern worldthing_t *things;

int LineByPoint (NSPoint *pt, int *side);

