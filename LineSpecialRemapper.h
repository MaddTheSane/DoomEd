#import	"Remapper.h"
#import <AppKit/AppKit.h>

@class LineSpecialRemapper;
extern LineSpecialRemapper *lineSpecialRemapper_i;

@interface LineSpecialRemapper:NSObject <Remapper>
{
	IBOutlet Remapper	*remapper_i;
}

- (void)addToList: (NSString *) orgname to: (NSString *) newname;
- (IBAction)menuTarget:sender;

@end
