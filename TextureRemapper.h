#import	"Remapper.h"
#import <AppKit/AppKit.h>

@interface TextureRemapper:Remapper <RemapperDelegate>
{
	
}

- (void)addToList: (NSString *) orgname to: (NSString *) newname;

@end

extern TextureRemapper *textureRemapper_i;

