// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "Wadfile.h"
#import "idfunctions.h"
#import <ctype.h>

#ifdef REDOOMED
#   import <fcntl.h>
#   import <unistd.h>
#   import <string.h>
#endif

typedef struct
{
	char		identification[4];		// should be IWAD
	int		numlumps;
	int		infotableofs;
} wadinfo_t;


typedef struct
{
	int		filepos;
	int		size;
	char		name[8];
} lumpinfo_t;


#ifdef REDOOMED
static char *RDE_ZeroTerminatedStringWithMaxLength(char *string, int maxLength);
#endif


@implementation Wadfile

//=============================================================================

/*
============
=
= initFromFile:
=
============
*/

- (instancetype)initFromFile: (char const *)path
{
	wadinfo_t	wad;
	lumpinfo_t	*lumps;
	int			i;
	
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	pathname = malloc(strlen(path)+1);

#ifdef REDOOMED
	if (!pathname)
	{
		[self release];
		return nil;
	}
#endif

	strcpy (pathname, path);
	dirty = NO;
	handle = open (pathname, O_RDWR, 0666);
	if (handle== -1)
	{
		[self release];
		return nil;
	}
//
// read in the header
//
	read (handle, &wad, sizeof(wad));
	if (strncmp(wad.identification,"IWAD",4))
	{
		close (handle);
		[self release];
		return nil;
	}
	wad.numlumps = LongSwap (wad.numlumps);
	wad.infotableofs = LongSwap (wad.infotableofs);
	
//
// read in the lumpinfo
//
	lseek (handle, wad.infotableofs, L_SET);
	info = [[Storage alloc] initCount: wad.numlumps elementSize: sizeof(lumpinfo_t) description: ""];
	lumps = [info elementAt: 0];
	
	read (handle, lumps, wad.numlumps*sizeof(lumpinfo_t));
	for (i=0 ; i<wad.numlumps ; i++, lumps++)
	{
		lumps->filepos = LongSwap (lumps->filepos);
		lumps->size = LongSwap (lumps->size);
	}
	
	return self;
}


/*
============
=
= initNew:
=
============
*/

- (instancetype)initNew: (char const *)path
{
	wadinfo_t	wad;

#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	pathname = malloc(strlen(path)+1);

#ifdef REDOOMED
	if (!pathname)
	{
		[self release];
		return nil;
	}
#endif

	strcpy (pathname, path);
	info = [[Storage alloc] initCount: 0 elementSize: sizeof(lumpinfo_t) description: ""];
	dirty = YES;
	handle = open (pathname, O_CREAT | O_TRUNC | O_RDWR, 0666);
	if (handle== -1)
#ifdef REDOOMED
	{
		// prevent memory leaks
		[self release];
#endif
		return nil;
#ifdef REDOOMED
	}
#endif

// leave space for wad header
	write (handle, &wad, sizeof(wad));
	
	return self;
}

// changed the close method to return void to match the close method signature used in
// several Cocoa classes (fixes the compiler warning about multiple methods)
- (void) close;
{
	close (handle);
}

// Cocoa compatibility: dealloc method replaces free method
- (void) dealloc
{
	// handle may be invalid (0 or -1)
	if ((handle != 0) && (handle != -1))
	{
		close (handle);
	}

	[info release];

	// pathname may be invalid (NULL)
	if (pathname != NULL)
	{
		free (pathname);
	}

	[super dealloc];
}

//=============================================================================

- (NSInteger)countOfLumps
{
	return [info count];
}

- (int)lumpsize: (int)lump
{
	lumpinfo_t	*inf;
	inf = [info elementAt: lump];
	return inf->size;
}

- (int)lumpstart: (int)lump
{
	lumpinfo_t	*inf;
	inf = [info elementAt: lump];
	return inf->filepos;
}

- (char const *)lumpname: (int)lump
{
	lumpinfo_t	*inf;
	inf = [info elementAt: lump];

#ifdef REDOOMED
	// Bugfix: prevent crash due to a non-terminated string - inf->name is a char[8], and it
	// sometimes contains a string of length 8 (no terminating char)
	return RDE_ZeroTerminatedStringWithMaxLength(inf->name, sizeof(inf->name));
#else
	return inf->name;
#endif
}

/*
================
=
= lumpNamed:
=
================
*/

- (NSInteger)lumpNamed: (char const *)name
{
	lumpinfo_t	*inf;
	NSInteger	i, count;
	char		name8[9];
	int			v1,v2;

// make the name into two integers for easy compares

	memset(name8,0,9);
	if (strlen(name) < 9)
		strncpy (name8,name,9);
	for (i=0 ; i<9 ; i++)
		name8[i] = toupper(name8[i]);	// case insensitive

	v1 = *(int *)name8;
	v2 = *(int *)&name8[4];


// scan backwards so patch lump files take precedence

	count = [info count];
	for (i=count-1 ; i>=0 ; i--)
	{
		inf = [info elementAt: i];
		if ( *(int *)inf->name == v1 && *(int *)&inf->name[4] == v2)
			return i;
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

- (void *)loadLump: (int)lump
{
	lumpinfo_t	*inf;
	byte			*buf;
	
	inf = [info elementAt: lump];
	buf = malloc (inf->size);
	
	lseek (handle, inf->filepos, SEEK_SET);
	read (handle, buf, inf->size);
	
	return buf;
}

- (void *)loadLumpNamed: (char const *)name
{
	return [self loadLump:[self lumpNamed: name]];
}

//============================================================================

/*
================
=
= addName:data:size:
=
================
*/

- (void)addName: (char const *)name data: (void *)data size: (int)size
{
	int		i;
	lumpinfo_t	new;
	
	dirty = YES;
	memset (new.name,0,sizeof(new.name));
	strncpy (new.name, name, 8);
	for (i=0 ; i<8 ; i++)
		new.name[i] = toupper(new.name[i]);
	new.filepos = (int)lseek(handle,0, SEEK_END);
	new.size = size;
	[info addElement: &new];
	
	write (handle, data, size);
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
	int			i,count;
	lumpinfo_t	*inf;
	
//
// write the directory
//
	count = [info count];
	inf = [info elementAt:0];
	for (i=0 ; i<count ; i++)
	{
		inf[i].filepos = LongSwap (inf[i].filepos);
		inf[i].size = LongSwap (inf[i].size);
	}
	wad.infotableofs = LongSwap ((int)lseek(handle,0, L_XTND));
	write (handle, inf, count*sizeof(lumpinfo_t));
	for (i=0 ; i<count ; i++)
	{
		inf[i].filepos = LongSwap (inf[i].filepos);
		inf[i].size = LongSwap (inf[i].size);
	}
	
//
// write the header
//
	strncpy (wad.identification, "IWAD",4);
	wad.numlumps = LongSwap ((int)[info count]);
	lseek (handle, 0, L_SET);
	write (handle, &wad, sizeof(wad));
}

@end

#ifdef REDOOMED
//  RDE_ZeroTerminatedStringWithMaxLength() accepts a string which might not be zero-terminated,
// and returns a valid terminated string with up to maxLength chars. If the input string wasn't
// terminated, the returned string is an autoreleased copy. (Used by -[Wadfile lumpname:]).

static char *RDE_ZeroTerminatedStringWithMaxLength(char *string, int maxLength)
{
	bool stringIsZeroTerminated = (memchr(string, 0, maxLength) != NULL);

	if (!stringIsZeroTerminated)
	{
		char *terminatedString =
                        (char *) [[NSMutableData dataWithLength: maxLength + 1] mutableBytes];

		strncpy(terminatedString, string, maxLength);
		terminatedString[maxLength] = 0;

		string = terminatedString;
	}

	return string;
}

#endif
