// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"Remapper.h"

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

extern	id	thingRemapper_i;

@interface ThingRemapper:Object <Remapper>
{
	id	remapper_i;
}

- menuTarget:sender;
- addToList:(char *)orgname to:(char *)newname;

@end
