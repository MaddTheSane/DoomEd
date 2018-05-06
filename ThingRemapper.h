#import	"Remapper.h"
#import <AppKit/AppKit.h>

@class ThingRemapper;
extern ThingRemapper *thingRemapper_i;

@interface ThingRemapper:Remapper <Remapper>

- (IBAction)menuTarget:sender;
- (void)addToList: (NSString *) orgname to: (NSString *) newname;

@end
