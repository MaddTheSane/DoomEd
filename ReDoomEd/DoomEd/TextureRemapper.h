// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"Remapper.h"

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

extern	id	textureRemapper_i;

@interface TextureRemapper:Object <Remapper>
{
	id	remapper_i;
}

- addToList:(char *)orgname to:(char *)newname;

@end
