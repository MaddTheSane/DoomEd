#import	"Remapper.h"
#import <AppKit/AppKit.h>

@class ThingRemapper;
extern ThingRemapper *thingRemapper_i;

@interface ThingRemapper:Remapper <RemapperDelegate>

- (IBAction)menuTarget:sender;

@end
