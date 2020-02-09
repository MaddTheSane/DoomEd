// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@class Storage;

@interface Wadfile : NSObject
{
	int		handle;
	char		*pathname;
	Storage	*info;
	BOOL	dirty;
}

- (instancetype)initFromFile: (char const *)path;
- (instancetype)initNew: (char const *)path;

- (void) close;

- (NSInteger)countOfLumps;
- (int)lumpsize: (int)lump;
- (int)lumpstart: (int)lump;
- (char const *)lumpname: (int)lump;
- (NSInteger)lumpNamed: (char const *)name;
- (void *)loadLump: (int)lump;
- (void *)loadLumpNamed: (char const *)name;

- (void)addName: (char const *)name data: (void *)data size: (int)size;
- (void)writeDirectory; 

@end
