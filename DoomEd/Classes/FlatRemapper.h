#import	"Remapper.h"
#import <AppKit/AppKit.h>

@class FlatRemapper;
extern FlatRemapper *flatRemapper_i;

@interface FlatRemapper:Remapper <RemapperDelegate>

@end
