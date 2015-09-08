#import "Storage.h"

#import <appkit/appkit.h>


@interface Wadfile : NSObject
{
	int		handle;
	char		*pathname;
	CompatibleStorage *info;
	BOOL	dirty;
}

- (instancetype)initFromFile: (char const *)path;
- (instancetype)initNew: (char const *)path;
- (void)close;

- (int)numLumps;
- (int)lumpsize: (int)lump;
- (int)lumpstart: (int)lump;
- (char const *)lumpname: (int)lump;
- (int)lumpNamed: (char const *)name;
- (void *)loadLump: (int)lump;
- (void *)loadLumpNamed: (char const *)name;

- (void)addName: (char const *)name data: (void *)data size: (int)size;
- (void)writeDirectory;

@end
