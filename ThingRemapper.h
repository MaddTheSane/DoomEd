#import	"Remapper.h"
#import <appkit/appkit.h>

extern	id	thingRemapper_i;

@interface ThingRemapper:NSObject <Remapper>
{
	IBOutlet id	remapper_i;
}

- (IBAction)menuTarget:sender;
- (void)addToList: (NSString *) orgname to: (NSString *) newname;

@end
