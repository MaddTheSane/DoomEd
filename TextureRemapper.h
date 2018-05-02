#import	"Remapper.h"
#import <AppKit/AppKit.h>

@interface TextureRemapper:Remapper <Remapper>
{
	
}

- (void)addToList: (NSString *) orgname to: (NSString *) newname;

@end

extern TextureRemapper *textureRemapper_i;

