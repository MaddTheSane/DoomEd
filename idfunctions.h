#import <AppKit/AppKit.h>

#ifndef __BYTEBOOL__
#define __BYTEBOOL__
typedef unsigned char byte;
#endif

typedef struct
{
	float	left, bottom, right, top;
} box_t;

void BoxFromRect (box_t *box, NSRect *rect);
void BoxFromPoints (box_t *box, NSPoint *p1, NSPoint *p2);

void IDRectFromPoints( NSRect *rect, NSPoint const *p1, NSPoint const *p2 );
void IDEnclosePoint (NSRect *rect, NSPoint const *point);

unsigned short ShortSwap (unsigned short dat);
unsigned LongSwap (unsigned dat);
off_t filelength (int handle);
off_t tell (int handle);

void BackupFile (char const *fname);

void DefaultExtension (char *path, const char *extension);
void DefaultPath (char *path, char *basepath);

void StripExtension (char *path);
void StripFilename (char *path);
void ExtractFileName (const char *path, char *dest);

void IdException (char const *format, ...) __printflike(1, 2);
