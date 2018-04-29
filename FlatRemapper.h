#import	"Remapper.h"
#import <AppKit/AppKit.h>

@class FlatRemapper;
extern FlatRemapper *flatRemapper_i;

@interface FlatRemapper:NSObject <Remapper>
{
	IBOutlet Remapper	*remapper_i;
}

- (void)addToList: (NSString *) orgname to: (NSString *) newname;

@end
