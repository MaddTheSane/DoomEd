#import "Storage.h"

#import "idfunctions.h"
#import <appkit/appkit.h>
#import "EditWorld.h"
#import	"TexturePatchView.h"


#define	SPACING				10

@interface TextureEdit:NSObject
{
	IBOutlet id	window_i;				// Texture Editor window
	IBOutlet id	textureView_i;				// texture editing area
	IBOutlet id	texturePatchWidthField_i;	// under Patch Palette (information)
	IBOutlet id	texturePatchHeightField_i;	// . . .
	IBOutlet id	texturePatchNameField_i;
	IBOutlet id	texturePatchXField_i;
	IBOutlet id	texturePatchYField_i;
	IBOutlet id	textureWidthField_i;	// at top of window
	IBOutlet id	textureHeightField_i;	// . . .
	IBOutlet id	textureNameField_i;
	IBOutlet id	patchWidthField_i;		// under Patch Palette
	IBOutlet id	patchHeightField_i;		// . . .
	IBOutlet id	patchNameField_i;
	IBOutlet id	scrollView_i;			// texture editing area
	IBOutlet id	outlinePatches_i;		// switch
	IBOutlet id	lockedPatch_i;			// switch
	IBOutlet id	centerPatch_i;			// switch
	IBOutlet id	texturePatchScrollView_i;	// Patch Palette
	IBOutlet id	texturePatchView_i;		// Patch Palette
	IBOutlet id	dragWarning_i;			// warning for dragging selections outside
	IBOutlet id	splitView_i;			// NXSplitView!
	IBOutlet id	topView_i;
	IBOutlet id	botView_i;

	IBOutlet id	createTexture_i;		// Create Texture window
	IBOutlet id	createWidth_i;			// in Create Texture dialog
	IBOutlet id	createHeight_i;			// . . .
	IBOutlet id	createName_i;
	IBOutlet id	createDone_i;			// "Create" button
	IBOutlet id	setMatrix_i;			// Texture Set radio-button matrix
	IBOutlet id	textureSetField_i;		// Texture Set field in Texture Editor
	IBOutlet id	newSetButton_i;			// Create New Set button
	IBOutlet id	patchSearchField_i;		// Search for patch string

	CompatibleStorage *patchImages;		// Patch Palette images
	
	int	selectedPatch;			// in the Patch Palette
	CompatibleStorage *selectedTexturePatches;	// in the Texture Editor View
	CompatibleStorage *copyList;		// list of copied patches
	int	currentTexture;			// being edited
	int	oldx,oldy;				// last texture x,y
}

typedef struct
{
	int	sel;
} store_t;

// a patch holds one or more collumns
// Some patches will be in native color, while be used with a color remap table
typedef struct
{
	short	width;				// bounding box size
	short	height;
	short	leftoffset;			// pixels to the left of origin
	short	bottomoffset;		// pixels below the origin
	int		collumnofs[256];	// only [width] used, the [0] is
								// &collumnofs[width]
} patch_t;

typedef struct
{
	byte		topdelta;			// -1 is the last post in a collumn
	byte		length;
// length data bytes follow
} post_t;

// collumn_t is a list of 0 or more post_t, (byte)-1 terminated
typedef post_t	collumn_t;

//
// structure for loaded patches
//
typedef struct
{
	NSRect	r;
	NSSize	size;
	char		name[9];
	id		image;
	id		image_x2;
	int		WADindex;
} apatch_t;

typedef	struct
{
	int	patchLocked;
	NSRect	r;
	worldpatch_t	patchInfo;
	apatch_t		*patch;
} texpatch_t;

- (int)numSets;
- (IBAction)findPatch:sender;
- (IBAction)searchForPatch:sender;
- (IBAction)changedWidthOrHeight:sender;
- (void)setOldVars:(int)x :(int)y;
- (void)doLockToggle;
- (IBAction)togglePatchLock:sender;
- (IBAction)deleteCurrentPatch:sender;
- (IBAction)sortUp:sender;
- (IBAction)sortDown:sender;

- (void)updateTexPatchInfo;
- (CompatibleStorage *) getSTP;
- (void)changeSelectedTexturePatch:(int)which	to:(int)val;
- (void)addSelectedTexturePatch:(int)val;
- (BOOL) selTextureEditPatchExists:(int)val;
- (void)removeSelTextureEditPatch:(int)val;
- (int)getCurrentEditPatch;
- (int)findHighestNumberedPatch;
- (IBAction)changePatchX:sender;
- (IBAction)changePatchY:sender;

- (IBAction)outlineWasSet:sender;
- (apatch_t *)getPatch:(int)which;
- (apatch_t *)getPatchImage:(char *)name;
- (IBAction)finishTexture:sender;
- (void)addPatch:(int)which;
- (IBAction)sizeChanged:sender;
- (IBAction)fillWithPatch:sender;
- (IBAction)menuTarget:sender;
- (int)getCurrentTexture;
- (int)getCurrentPatch;

- (IBAction)makeNewTexture:sender;
- (IBAction)createTextureDone:sender;
- (IBAction)createTextureName:sender;
- (IBAction)createTextureAbort:sender;
- (IBAction)createNewSet:sender;

- (void)newSelection:(int)which;
- (void)setSelectedPatch:(int)which;
- (void)selectPatchAndScroll:(int)patch;
- (int)getOutlineFlag;
- (void)dumpAllPatches;
- (void)initPatches;
- (void)createPatchX2:(apatch_t *)p;
- (void)computePatchDocView: (NSRect *)theframe;
- (void)setWarning:(BOOL)state;
- (void)saveFrame;

- (int)getNumPatches;
- (int)findPatchIndex:(char *)name;
- (char *)getPatchName:(int)which;

- (IBAction)locatePatchInTextures:sender;

@end

extern CompatibleStorage *texturePatches;
extern TextureEdit *textureEdit_i;

id	patchToImage(patch_t *patchData, unsigned short *shortpal,
	NSSize *size,char *name);

