#import	"Remapper.h"
#import <appkit/appkit.h>

extern	id	lineSpecialRemapper_i;

@interface LineSpecialRemapper:NSObject <Remapper>
{
	IBOutlet id	remapper_i;
}

- (void)addToList: (NSString *) orgname to: (NSString *) newname;
- (IBAction)menuTarget:sender;

@end
