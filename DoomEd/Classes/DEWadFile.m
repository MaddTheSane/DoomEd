#import "DEWadFile.h"
#import "idfunctions.h"
#import <ctype.h>

typedef struct wadinfo_s
{
	char	identification[4];		// should be IWAD
	int		numlumps;
	int		infotableofs;
} wadinfo_t;


typedef struct lumpinfo_s
{
	int		filepos;
	int		size;
	char	name[8];
} lumpinfo_t;

#if !__has_feature(objc_arc)
#error BUILD WITH ARC!
#endif

@interface DELumpInfo()
- (instancetype)initWithLumpInfoStruct:(lumpinfo_t)lumpInfo;

@property (readonly) lumpinfo_t lumpInfo;
@end

@implementation DELumpInfo

- (instancetype)initWithLumpInfoStruct:(lumpinfo_t)lumpInfo
{
	if (self = [self init]) {
		char fullName[9];
		self.filePosition = lumpInfo.filepos;
		self.dataSize = lumpInfo.size;
		memcpy(fullName, lumpInfo.name, sizeof(lumpInfo.name));
		fullName[8] = 0;
		self.name = @(fullName);
	}
	return self;
}

- (lumpinfo_t)lumpInfo
{
	lumpinfo_t toRet;
	toRet.size = _dataSize;
	toRet.filepos = _filePosition;
	strncpy (toRet.name, self.name.UTF8String, 8);
	return toRet;
}
@end


@implementation DEWadFile

//=============================================================================

/*
============
=
= initWithFilePath:
=
============
*/

- (instancetype)initWithFilePath: (NSString *)path
{
	if (self = [super init]) {
		wadinfo_t	wad;
		lumpinfo_t	*lumps, *lumpsStart;
		int			i;
		
		pathname = [path copy];
		dirty = NO;
		handle = open (pathname.fileSystemRepresentation, O_RDWR, 0666);
		if (handle == -1)
		{
			return nil;
		}
		//
		// read in the header
		//
		read (handle, &wad, sizeof(wad));
		if (strncmp(wad.identification, "IWAD", 4)) {
			close (handle);
			return nil;
		}
		wad.numlumps = LongSwap (wad.numlumps);
		wad.infotableofs = LongSwap (wad.infotableofs);
		
		//
		// read in the lumpinfo
		//
		lseek (handle, wad.infotableofs, SEEK_SET);
		info = [[NSMutableArray alloc] initWithCapacity:wad.numlumps];
		
		lumpsStart = lumps = calloc(wad.numlumps, sizeof(lumpinfo_t));
		
		
		read (handle, lumps, wad.numlumps*sizeof(lumpinfo_t));
		for (i=0 ; i<wad.numlumps ; i++, lumps++)
		{
			lumps->filepos = LongSwap (lumps->filepos);
			lumps->size = LongSwap (lumps->size);
		}
		
		for (i=0; i<wad.numlumps; i++) {
			[info addObject:[[DELumpInfo alloc] initWithLumpInfoStruct:lumpsStart[i]]];
		}
		
		free(lumpsStart);
	}
	return self;
}

/*
============
=
= initNewWithPath:
=
============
*/

- (instancetype)initNewWithPath: (NSString *)path
{
	if (self = [super init]) {
		wadinfo_t	wad;
		
		pathname = [path copy];
		info = [[NSMutableArray alloc] init];
		dirty = YES;
		handle = open (pathname.fileSystemRepresentation, O_CREAT | O_TRUNC | O_RDWR, 0666);
		if (handle== -1)
			return nil;
		// leave space for wad header
		write (handle, &wad, sizeof(wad));
	}
	
	return self;
}

-(void)close
{
	close (handle);
}

- (void) dealloc
{
	[self close];
}

//=============================================================================

- (NSInteger)countOfLumps
{
	return [info count];
}

- (int)sizeOfLumpAtIndex: (NSInteger)lump
{
	DELumpInfo	*inf;
	inf = [info objectAtIndex: lump];
	return inf.dataSize;
}

- (int)startOfLumpAtIndex: (NSInteger)lump
{
	DELumpInfo	*inf;
	inf = [info objectAtIndex: lump];
	return inf.filePosition;
}

- (NSString *)nameOfLumpAtIndex: (NSInteger)lump;
{
	DELumpInfo	*inf;
	inf = [info objectAtIndex: lump];
	return inf.name;
}

/*
================
=
= lumpNamed:
=
================
*/

- (NSInteger)indexOfLumpNamed: (NSString *)name
{
	DELumpInfo	*inf;
	NSInteger	i, count;
	
	// scan backwards so patch lump files take precedence
	
	count = [info count];
	for (i=count-1 ; i>=0 ; i--)
	{
		inf = [info objectAtIndex: i];
		if ([name caseInsensitiveCompare:inf.name] == NSOrderedSame) {
			return i;
		}
	}
	return  NSNotFound;
}

/*
================
=
= loadLump:
=
================
*/

- (NSData *)dataOfLumpAtIndex: (NSInteger)lump
{
	DELumpInfo		*inf;
	NSMutableData	*buf;
	if (lump == NSNotFound) {
		return nil;
	}
	
	inf = [info objectAtIndex: lump];
	buf = [NSMutableData dataWithLength:inf.dataSize];
	
	lseek (handle, inf.filePosition, SEEK_SET);
	read (handle, buf.mutableBytes, inf.dataSize);
	
	return buf;
}

- (NSData *)dataOfLumpNamed: (NSString *)name
{
	return [self dataOfLumpAtIndex:[self indexOfLumpNamed: name]];
}

//============================================================================

/*
================
=
= addName:data:size:
=
================
*/

- (void)addIndexWithName: (NSString *)name data: (NSData *)data;
{
	DELumpInfo	*new;
	
	dirty = YES;
	new = [[DELumpInfo alloc] init];
	new.name = name.uppercaseString;
	new.filePosition = (int)lseek(handle,0, SEEK_END);
	new.dataSize = (int)data.length;
	[info addObject: new];
	
	write (handle, data.bytes, data.length);
}


/*
================
=
= writeDirectory:
=
	char		identification[4];		// should be IWAD
	int		numlumps;
	int		infotableofs;
================
*/

- (void)writeDirectory
{
	wadinfo_t	wad;
	lumpinfo_t	inf;
	
	//
	// write the directory
	//
	
	for (DELumpInfo *li in info) {
		inf = li.lumpInfo;
		inf.filepos = LongSwap(inf.filepos);
		inf.size = LongSwap(inf.size);
		write (handle, &inf, sizeof(lumpinfo_t));
	}
	wad.infotableofs = LongSwap ((unsigned int)lseek(handle,0, SEEK_END));
	
	//
	// write the header
	//
	memcpy (wad.identification, "IWAD",4);
	wad.numlumps = LongSwap ((unsigned)[info count]);
	lseek (handle, 0, SEEK_SET);
	write (handle, &wad, sizeof(wad));
}

@end

