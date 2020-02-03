// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

#ifdef REDOOMED
    // Import "R_mapdef.h" for its modified __BYTEBOOL__ typedefs
    // (updated for Cocoa compatibility)
#   import "R_mapdef.h"
#endif

#ifndef __BYTEBOOL__
#define __BYTEBOOL__
typedef unsigned char byte;
typedef enum {false, true} boolean;
#endif

typedef struct
{
	float	left, bottom, right, top;
} box_t;

void BoxFromRect (box_t *box, NXRect *rect);
void BoxFromPoints (box_t *box, NXPoint *p1, NXPoint *p2);

void IDRectFromPoints( NXRect *rect, NXPoint const *p1, NXPoint const *p2 );
void IDEnclosePoint (NXRect *rect, NXPoint const *point);

unsigned short ShortSwap (unsigned short dat);
unsigned LongSwap (unsigned dat);
int filelength (int handle);
int tell (int handle);

void BackupFile (char const *fname);

void DefaultExtension (char *path, char *extension);
void DefaultPath (char *path, char *basepath);

void StripExtension (char *path);
void StripFilename (char *path);
void ExtractFileName (char *path, char *dest);

void IdException (char const *format, ...) __printflike(1, 2);
