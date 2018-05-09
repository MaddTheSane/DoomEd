#import	"Remapper.h"
#import <AppKit/AppKit.h>

@class LineSpecialRemapper;
extern LineSpecialRemapper *lineSpecialRemapper_i;

@interface LineSpecialRemapper:Remapper <RemapperDelegate>

- (void)addToList: (NSString *) orgname to: (NSString *) newname;
- (IBAction)menuTarget:sender;

@end
