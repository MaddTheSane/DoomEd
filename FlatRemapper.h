#import	"Remapper.h"
#import <AppKit/AppKit.h>

extern	id	flatRemapper_i;

@interface FlatRemapper:NSObject <Remapper>
{
	IBOutlet id	remapper_i;
}

- (void)addToList: (NSString *) orgname to: (NSString *) newname;

@end
