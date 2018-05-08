#import "Storage.h"

#import	"TextureEdit.h"
#import <AppKit/AppKit.h>

@class TexturePalView;

typedef struct texpal_s
{
	NSImage	*image;
	int	patchamount;
	char	 name[9];
	NSRect	r;
	int	WADindex;
	int	oldIndex;
} texpal_t;

@interface TexturePalette:NSObject <NSWindowDelegate>
{
	IBOutlet NSWindow		*window_i;
	IBOutlet TexturePalView	*texturePalView_i;
	IBOutlet NSScrollView	*texturePalScrView_i;
	IBOutlet NSTextField	*titleField_i;
	IBOutlet NSTextField	*widthField_i;
	IBOutlet NSTextField	*heightField_i;
	IBOutlet NSTextField	*searchField_i;
	IBOutlet NSTextField	*patchField_i;
	IBOutlet NSTextField	*widthSearch_i;
	IBOutlet NSTextField	*heightSearch_i;
	
	id	texturePatches;
	CompatibleStorage *allTextures;
	CompatibleStorage *newTextures;
	int	selectedTexture;
	IBOutlet NSTextField	*lsTextField_i;
	IBOutlet NSPanel		*lsPanel_i;
	IBOutlet NSTextField	*lsStatus_i;
}

- (void)setupPalette;
- (void)initTextures;
- (void)finishInit;
- (IBAction)searchForTexture:sender;
- (int) getNumTextures;
- (int) getTextureIndex:(char *)name;
- (void)createAllTextureImages;
- (texpal_t) createTextureImage:(int)which;

- (void)computePalViewSize;
- (texpal_t *)getNewTexture:(int)which;
- (int)selectTextureNamed:(const char *)name;

- (texpal_t *)getTexture:(int)which;
- (void)storeTexture:(int)which;
- (char *)getSelTextureName;
- (void)setSelTexture:(const char *)name;
- (int) currentSelection;
- (void)selectTexture:(int)val;
- (IBAction)menuTarget:sender;
- (void)saveFrame;

- (IBAction)searchWidth:sender;
- (IBAction)searchHeight:sender;
- (IBAction)showTextureInMap:sender;

- (IBAction)saveTextureLBM:sender;
- (IBAction)saveAllTexturesAsLBM:sender;
- (IBAction)doSaveAllTexturesAsLBM:sender;

@end

extern TexturePalette *texturePalette_i;

//
//	Converting a texture to an LBM
//
void vgaPatchDecompress(patch_t *patchData,byte *dest_p);
void moveVgaPatch(byte *raw, byte *dest, int x, int y,
	int	width, int height,
	int clipwidth, int clipheight);
void createVgaTexture(char *dest, int which,int width, int height);
void createAndSaveLBM(const char *name, int cs, FILE *fp);

