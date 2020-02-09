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
@class TextureEdit;

typedef struct
{
	int	sel;
} store_t;

//! a patch holds one or more collumns.
//! Some patches will be in native color, while be used with a color remap table
typedef struct patch_t {
	//! bounding box size
	short	width, height;
	
	//! pixels to the left of origin
	short	leftoffset;
	
	//! pixels below the origin
	short	bottomoffset;
	//! only [width] used, the [0] is
	//! &collumnofs[width]
	int		collumnofs[256];
} patch_t;

typedef struct
{
	byte		topdelta;			// -1 is the last post in a collumn
	byte		length;
// length data bytes follow
} post_t;

/// \c collumn_t is a list of 0 or more post_t, (byte)-1 terminated
typedef post_t	collumn_t;

///
/// structure for loaded patches
///
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

extern Storage *texturePatches;
extern TextureEdit *textureEdit_i;

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
	IBOutlet NSScrollView *texturePatchScrollView_i;// Patch Palette
	IBOutlet TexturePatchView *texturePatchView_i;	// Patch Palette
	IBOutlet NSTextField *dragWarning_i;			// warning for dragging selections outside
	IBOutlet NSSplitView *splitView_i;
	IBOutlet NSBox *topView_i;
	IBOutlet NSBox *botView_i;

	IBOutlet NSPanel *createTexture_i;		// Create Texture window
	IBOutlet NSTextField *createWidth_i;	// in Create Texture dialog
	IBOutlet NSTextField *createHeight_i;	// . . .
	IBOutlet NSTextField *createName_i;
	IBOutlet NSButton *createDone_i;			//!< "Create" button
	IBOutlet NSMatrix *setMatrix_i;				//!< Texture Set radio-button matrix
	IBOutlet NSTextField *textureSetField_i;	//!< Texture Set field in Texture Editor
	IBOutlet NSButton	*newSetButton_i;		//!< Create New Set button
	IBOutlet NSTextField	*patchSearchField_i;//!< Search for patch string

	Storage	*patchImages;			//!< Patch Palette images
	
	int	selectedPatch;			//!< in the Patch Palette
	Storage	*selectedTexturePatches;	//!< in the Texture Editor View
	Storage	*copyList;			//!< list of copied patches
	int	currentTexture;			//!< being edited
	int	oldx,oldy;				//!< last texture x,y
}

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
@property (readonly, retain) Storage *selectedTexturePatches;
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
- (apatch_t *)getPatchImage:(const char *)name;
- (IBAction)finishTexture:sender;
- (void)addPatch:(int)which;
- (IBAction)sizeChanged:sender;
- (IBAction)fillWithPatch:sender;
- (IBAction)menuTarget:sender;
@property (readonly) int currentTexture;
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
- (void)computePatchDocView: (NXRect *)theframe;
- (void)setWarning:(BOOL)state;
- (void)saveFrame;

- (NSInteger)countOfPatches;
- (NSInteger)findPatchIndex:(const char *)name;
- (const char *)getPatchName:(NSInteger)which;

- (IBAction)locatePatchInTextures:sender;

@end

NSImage	*patchToImage(patch_t *patchData, unsigned short *shortpal,
	NXSize *size,const char *name) NS_RETURNS_RETAINED;
char *strupr(char *string);
char *strlwr(char *string);
