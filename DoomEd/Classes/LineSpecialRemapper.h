#import	"Remapper.h"
#import <AppKit/AppKit.h>

@class LineSpecialRemapper;
extern LineSpecialRemapper *lineSpecialRemapper_i;

@interface LineSpecialRemapper:Remapper <RemapperDelegate>

- (IBAction)menuTarget:sender;

@end
