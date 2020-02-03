// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"TextureEdit.h"

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@class TexturePalette;
@class TexturePalView;
@class Storage;

extern TexturePalette *texturePalette_i;

typedef struct
{
	NSImage	*image;
	int	patchamount;
	char	 name[9];
	NXRect	r;
	int	WADindex;
	int	oldIndex;
} texpal_t;

@interface TexturePalette:Object <NSWindowDelegate>
{
	IBOutlet NSWindow *window_i;
	IBOutlet TexturePalView *texturePalView_i;
	IBOutlet NSScrollView	*texturePalScrView_i;
	IBOutlet NSTextField	*titleField_i;
	IBOutlet NSTextField	*widthField_i;
	IBOutlet NSTextField	*heightField_i;
	IBOutlet NSTextField	*searchField_i;
	IBOutlet NSTextField	*patchField_i;
	IBOutlet NSTextField	*widthSearch_i;
	IBOutlet NSTextField	*heightSearch_i;
	
	id	texturePatches;
	Storage	*allTextures;
	id	newTextures;
	int	selectedTexture;
	IBOutlet NSTextField	*lsTextField_i;
	IBOutlet NSPanel	*lsPanel_i;
	IBOutlet NSTextField	*lsStatus_i;
}

- setupPalette;
- initTextures;
- finishInit;
- (IBAction)searchForTexture:sender;
- (NSInteger) getNumTextures;
- (NSInteger) getTextureIndex:(const char *)name;
- createAllTextureImages;
- (texpal_t) createTextureImage:(int)which;

- computePalViewSize;
- (texpal_t *)getNewTexture:(int)which;
- (int)selectTextureNamed:(char *)name;

- (texpal_t *)getTexture:(int)which;
- storeTexture:(int)which;
- (char *)getSelTextureName;
- setSelTexture:(char *)name;
- (int) currentSelection;
- selectTexture:(int)val;
- (IBAction)menuTarget:sender;
- saveFrame;

- (IBAction)searchWidth:sender;
- (IBAction)searchHeight:sender;
- (IBAction)showTextureInMap:sender;

- (IBAction)saveTextureLBM:sender;
- (IBAction)saveAllTexturesAsLBM:sender;
- (IBAction)doSaveAllTexturesAsLBM:sender;

@end

//
//	Converting a texture to an LBM
//
void vgaPatchDecompress(patch_t *patchData,byte *dest_p);
void moveVgaPatch(byte *raw, byte *dest, int x, int y,
	int	width, int height,
	int clipwidth, int clipheight);
void createVgaTexture(char *dest, int which,int width, int height);
void createAndSaveLBM(char *name, int cs, FILE *fp);
