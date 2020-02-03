// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "idfunctions.h"

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

#import "EditWorld.h"
#import	"TexturePatchView.h"

@class Storage;
@class TextureView;
@class TexturePatchView;

#define	SPACING				10

@interface TextureEdit:NSObject <NSWindowDelegate, NSSplitViewDelegate>
{
	IBOutlet NSPanel *window_i;				// Texture Editor window
	IBOutlet TextureView *textureView_i;	// texture editing area
	IBOutlet NSTextField *texturePatchWidthField_i;		// under Patch Palette (information)
	IBOutlet NSTextField *texturePatchHeightField_i;	// . . .
	IBOutlet NSTextField *texturePatchNameField_i;
	IBOutlet NSTextField *texturePatchXField_i;
	IBOutlet NSTextField *texturePatchYField_i;
	IBOutlet NSTextField *textureWidthField_i;	// at top of window
	IBOutlet NSTextField *textureHeightField_i;	// . . .
	IBOutlet NSTextField *textureNameField_i;
	IBOutlet NSTextField *patchWidthField_i;		// under Patch Palette
	IBOutlet NSTextField *patchHeightField_i;		// . . .
	IBOutlet NSTextField *patchNameField_i;
	IBOutlet NSScrollView *scrollView_i;			// texture editing area
	IBOutlet NSButton *outlinePatches_i;			// switch
	IBOutlet NSButton *lockedPatch_i;				// switch
	IBOutlet NSButton *centerPatch_i;				// switch
	IBOutlet NSScrollView *texturePatchScrollView_i;	// Patch Palette
	IBOutlet TexturePatchView *texturePatchView_i;		// Patch Palette
	IBOutlet NSTextField *dragWarning_i;			// warning for dragging selections outside
	IBOutlet NSSplitView *splitView_i;			// NXSplitView!
	IBOutlet NSBox *topView_i;
	IBOutlet NSBox *botView_i;

	IBOutlet NSPanel *createTexture_i;		// Create Texture window
	IBOutlet NSTextField *createWidth_i;	// in Create Texture dialog
	IBOutlet NSTextField *createHeight_i;	// . . .
	IBOutlet NSTextField *createName_i;
	IBOutlet NSButton *createDone_i;			// "Create" button
	IBOutlet NSMatrix *setMatrix_i;				// Texture Set radio-button matrix
	IBOutlet NSTextField *textureSetField_i;	// Texture Set field in Texture Editor
	IBOutlet id	newSetButton_i;			// Create New Set button
	IBOutlet NSTextField	*patchSearchField_i;// Search for patch string

	Storage	*patchImages;			// Patch Palette images
	
	int	selectedPatch;			// in the Patch Palette
	id	selectedTexturePatches;	// in the Texture Editor View
	id	copyList;				// list of copied patches
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
	NXRect	r;
	NXSize	size;
	char		name[9];
	id		image;
	id		image_x2;
	int		WADindex;
} apatch_t;

typedef	struct
{
	int	patchLocked;
	NXRect	r;
	worldpatch_t	patchInfo;
	apatch_t		*patch;
} texpatch_t;



extern Storage *texturePatches;
extern TextureEdit *textureEdit_i;

- (int)numSets;
- (IBAction)findPatch:sender;
- (IBAction)searchForPatch:sender;
- (IBAction)changedWidthOrHeight:sender;
- setOldVars:(int)x :(int)y;
- doLockToggle;
- (IBAction)togglePatchLock:sender;
- (IBAction)deleteCurrentPatch:sender;
- (IBAction)sortUp:sender;
- (IBAction)sortDown:sender;

- updateTexPatchInfo;
- getSTP;
- changeSelectedTexturePatch:(int)which	to:(int)val;
- addSelectedTexturePatch:(int)val;
- (BOOL) selTextureEditPatchExists:(int)val;
- removeSelTextureEditPatch:(int)val;
- (int)getCurrentEditPatch;
- (int)findHighestNumberedPatch;
- (IBAction)changePatchX:sender;
- (IBAction)changePatchY:sender;

- (IBAction)outlineWasSet:sender;
- (apatch_t *)getPatch:(int)which;
- (apatch_t *)getPatchImage:(const char *)name;
- (IBAction)finishTexture:sender;
- addPatch:(int)which;
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

- newSelection:(int)which;
- setSelectedPatch:(int)which;
- selectPatchAndScroll:(int)patch;
- (int)getOutlineFlag;
- dumpAllPatches;
- initPatches;
- createPatchX2:(apatch_t *)p;
- computePatchDocView: (NXRect *)theframe;
- setWarning:(BOOL)state;
- saveFrame;

- (NSInteger)countOfPatches;
- (NSInteger)findPatchIndex:(const char *)name;
- (const char *)getPatchName:(NSInteger)which;

- (IBAction)locatePatchInTextures:sender;

@end

id	patchToImage(patch_t *patchData, unsigned short *shortpal,
	NXSize *size,const char *name);
char *strupr(char *string);
char *strlwr(char *string);
