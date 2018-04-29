#import	"Remapper.h"
#import <AppKit/AppKit.h>

extern	id	thingRemapper_i;

@interface ThingRemapper:NSObject <Remapper>
{
	IBOutlet Remapper	*remapper_i;
}

- (IBAction)menuTarget:sender;
- (void)addToList: (NSString *) orgname to: (NSString *) newname;

@end
