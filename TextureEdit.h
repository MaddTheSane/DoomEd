#import "Storage.h"

#import "idfunctions.h"
#import <AppKit/AppKit.h>
#import "EditWorld.h"
#import	"TexturePatchView.h"

@class TextureView;

#define	SPACING				10

@interface TextureEdit:NSObject <NSWindowDelegate, NSSplitViewDelegate>
{
	IBOutlet NSWindow			*window_i;					// Texture Editor window
	IBOutlet TextureView		*textureView_i;				// texture editing area
	IBOutlet NSTextField		*texturePatchWidthField_i;	// under Patch Palette (information)
	IBOutlet NSTextField		*texturePatchHeightField_i;	// . . .
	IBOutlet NSTextField		*texturePatchNameField_i;
	IBOutlet NSTextField		*texturePatchXField_i;
	IBOutlet NSTextField		*texturePatchYField_i;
	IBOutlet NSTextField		*textureWidthField_i;	// at top of window
	IBOutlet NSTextField		*textureHeightField_i;	// . . .
	IBOutlet NSTextField		*textureNameField_i;
	IBOutlet NSTextField		*patchWidthField_i;		// under Patch Palette
	IBOutlet NSTextField		*patchHeightField_i;	// . . .
	IBOutlet NSTextField		*patchNameField_i;
	IBOutlet NSScrollView		*scrollView_i;			// texture editing area
	IBOutlet NSButton			*outlinePatches_i;		// switch
	IBOutlet NSButton			*lockedPatch_i;			// switch
	IBOutlet NSButton			*centerPatch_i;			// switch
	IBOutlet NSScrollView		*texturePatchScrollView_i;	// Patch Palette
	IBOutlet TexturePatchView	*texturePatchView_i;		// Patch Palette
	IBOutlet NSTextField		*dragWarning_i;			// warning for dragging selections outside
	IBOutlet NSSplitView		*splitView_i;			// NXSplitView!
	IBOutlet NSBox				*topView_i;
	IBOutlet NSBox				*botView_i;

	IBOutlet NSPanel		*createTexture_i;		// Create Texture window
	IBOutlet NSTextField	*createWidth_i;			// in Create Texture dialog
	IBOutlet NSTextField	*createHeight_i;		// . . .
	IBOutlet NSTextField	*createName_i;
	IBOutlet NSButton		*createDone_i;			// "Create" button
	IBOutlet NSMatrix		*setMatrix_i;			// Texture Set radio-button matrix
	IBOutlet NSTextField	*textureSetField_i;		// Texture Set field in Texture Editor
	IBOutlet NSButton		*newSetButton_i;		// Create New Set button
	IBOutlet NSTextField	*patchSearchField_i;	// Search for patch string

	CompatibleStorage *patchImages;		// Patch Palette images
	
	int	selectedPatch;			// in the Patch Palette
	CompatibleStorage *selectedTexturePatches;	// in the Texture Editor View
	CompatibleStorage *copyList;		// list of copied patches
	int	currentTexture;			// being edited
	int	oldx,oldy;				// last texture x,y
}

typedef struct store_s
{
	int	sel;
} store_t;

// a patch holds one or more collumns
// Some patches will be in native color, while be used with a color remap table
typedef struct patch_s
{
	short	width;				// bounding box size
	short	height;
	short	leftoffset;			// pixels to the left of origin
	short	bottomoffset;		// pixels below the origin
	int		collumnofs[256];	// only [width] used, the [0] is
								// &collumnofs[width]
} patch_t;

typedef struct post_s
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
typedef struct apatch_s
{
	NSRect	r;
	NSSize	size;
	char		name[9];
	NSImage		*image;
	NSImage		*image_x2;
	int		WADindex;
} apatch_t;

typedef	struct texpatch_s
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

NSImage *patchToImage(patch_t *patchData, unsigned short *shortpal,
					  NSSize *size,char *name);
extern char *strupr(char *string);
extern char *strlwr(char *string);
