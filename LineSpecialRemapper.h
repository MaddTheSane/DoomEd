#import	"Remapper.h"
#import <AppKit/AppKit.h>

extern	id	lineSpecialRemapper_i;

@interface LineSpecialRemapper:NSObject <Remapper>
{
	IBOutlet id	remapper_i;
}

- (void)addToList: (NSString *) orgname to: (NSString *) newname;
- (IBAction)menuTarget:sender;

@end
