// cmdlib.h

// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifndef __CMDLIB__
#define __CMDLIB__

#ifdef REDOOMED
#   include <sys/types.h>
#   include <sys/stat.h>
#   include <fcntl.h>
#   include <string.h>
#   include <stdlib.h>
#   include <stdio.h>
#   include <unistd.h>

#   define __NeXT__ true
#endif  // REDOOMED

#ifdef __NeXT__

#   ifndef REDOOMED // Original (Disable for ReDoomEd)
#       include <libc.h>
#   endif

#include <errno.h>
#include <ctype.h>

#else

#include <ctype.h>
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <string.h>
#include <io.h>
#include <direct.h>
#include <process.h>
#include <dos.h>
#include <stdarg.h>
#include <conio.h>
#include <bios.h>

#endif

#ifdef __NeXT__
#define strcmpi strcasecmp
#define stricmp strcasecmp

#ifndef REDOOMED // Original (Disable for ReDoomEd - already declared in <unistd.h>)
char *getcwd (char *path, int length);
#endif

char *strupr (char *in);
int filelength (int handle);
int tell (int handle);
#endif

#ifndef __BYTEBOOL__
#define __BYTEBOOL__

#   ifdef REDOOMED
    // Cocoa compatibility: Define boolean as a 1-byte type
    typedef char boolean;
#   else // Original
    typedef enum {false, true} boolean;
#   endif

typedef unsigned char byte;
#endif


#ifndef __NeXT__
#define PATHSEPERATOR   '\\'
#endif

#ifdef __NeXT__

#define O_BINARY        0
#define PATHSEPERATOR   '/'

#endif

int		GetKey (void);

void	Error (char *error, ...);
int		CheckParm (char *check);

int 	SafeOpenWrite (char *filename);
int 	SafeOpenRead (char *filename);
void 	SafeRead (int handle, void *buffer, long count);
void 	SafeWrite (int handle, void *buffer, long count);
void 	*SafeMalloc (long size);

long	LoadFile (char *filename, void **bufferptr);
void	SaveFile (char *filename, void *buffer, long count);

void 	DefaultExtension (char *path, char *extension);
void 	DefaultPath (char *path, char *basepath);
void 	StripFilename (char *path);
void 	StripExtension (char *path);
void 	ExtractFileBase (const char *path, char *dest);

long 	ParseNum (char *str);

short	BigShort (short l);
short	LittleShort (short l);
int	BigLong (int l);
int	LittleLong (int l);

extern	byte	*screen;

#ifndef REDOOMED  // Original (Disable for ReDoomEd - unused, avoid name clashes with QD framework functions)
void 	GetPalette (byte *pal);
void 	SetPalette (byte *pal);
void 	VGAMode (void);
void 	TextMode (void);
#endif // Original

#endif
