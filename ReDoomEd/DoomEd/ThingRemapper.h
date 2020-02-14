// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"Remapper.h"

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@class ThingRemapper;
extern ThingRemapper *thingRemapper_i;

/// REMAP FLATS IN MAP
@interface ThingRemapper:NSObject <Remapper>
{
	Remapper *remapper_i;
}

- (IBAction)menuTarget:sender;
- (void)addToListFromName:(NSString *)orgname toName:(NSString *)newname;

@end
