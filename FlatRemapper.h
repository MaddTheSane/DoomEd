#import	"Remapper.h"
#import <AppKit/AppKit.h>

@class FlatRemapper;
extern FlatRemapper *flatRemapper_i;

@interface FlatRemapper:Remapper <Remapper>

- (void)addToList: (NSString *) orgname to: (NSString *) newname;

@end
