// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"Remapper.h"

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@class LineSpecialRemapper;
extern LineSpecialRemapper *lineSpecialRemapper_i;

@interface LineSpecialRemapper:NSObject <Remapper>
{
	Remapper *remapper_i;
}

- (void)addToList:(char *)orgname to:(char *)newname;
- (IBAction)menuTarget:sender;

@end
