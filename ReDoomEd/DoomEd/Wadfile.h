// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif


@interface Wadfile : Object
{
	int		handle;
	char		*pathname;
	id		info;
	BOOL	dirty;
}

- initFromFile: (char const *)path;
- initNew: (char const *)path;

#ifdef REDOOMED
// changed the close method to return void to match the close method signature used in
// several Cocoa classes (fixes the compiler warning about multiple methods)
- (void) close;
#else // Original
- close;
#endif

#ifndef REDOOMED // Original (Disable for ReDoomEd - free is declared by Object using a different sig)
- free;
#endif

- (int)numLumps;
- (int)lumpsize: (int)lump;
- (int)lumpstart: (int)lump;
- (char const *)lumpname: (int)lump;
- (int)lumpNamed: (char const *)name;
- (void *)loadLump: (int)lump;
- (void *)loadLumpNamed: (char const *)name;

- addName: (char const *)name data: (void *)data size: (int)size;
- writeDirectory; 

@end
