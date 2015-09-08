#import	"Remapper.h"
#import <appkit/appkit.h>

@interface TextureRemapper:NSObject <Remapper>
{
	IBOutlet id	remapper_i;
}

- (void)addToList: (NSString *) orgname to: (NSString *) newname;

@end

extern TextureRemapper *textureRemapper_i;

