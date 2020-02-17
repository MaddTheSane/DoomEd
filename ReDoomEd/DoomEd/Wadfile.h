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
- (int)lumpsize: (NSInteger)lump;
- (int)lumpstart: (NSInteger)lump;
- (char const *)lumpname: (NSInteger)lump;
- (NSInteger)lumpNamed: (char const *)name;
- (void *)loadLump: (NSInteger)lump;
- (void *)loadLumpNamed: (char const *)name;

- (void)addName: (char const *)name data: (void *)data size: (int)size;
- (void)writeDirectory; 

@end
