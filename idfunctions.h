#import <Foundation/Foundation.h>

#ifndef __BYTEBOOL__
#define __BYTEBOOL__
typedef unsigned char byte;
#endif

typedef struct box_s
{
	float	left, bottom, right, top;
} box_t;

void BoxFromRect (box_t *box, const NSRect *rect);
void BoxFromPoints (box_t *box, const NSPoint *p1, const NSPoint *p2);
box_t DEBoxFromRect (const NSRect rect);
box_t DEBoxFromPoints (const NSPoint p1, const NSPoint p2);

void IDRectFromPoints( NSRect *rect, NSPoint const *p1, NSPoint const *p2 );
void IDEnclosePoint (NSRect *rect, NSPoint const *point);

unsigned short ShortSwap (unsigned short dat);
unsigned LongSwap (unsigned dat);
off_t filelength (int handle);
off_t tell (int handle);

void BackupFile (NSString *fname);

void DefaultExtension (char *path, const char *extension);
void DefaultPath (char *path, char *basepath);

void StripExtension (char *path);
void StripFilename (char *path);
void ExtractFileName (const char *path, char *dest);

void IdException (char const *format, ...) __printflike(1, 2);


static inline unsigned short __ShortSwap (unsigned short dat)
{
	return CFSwapInt16LittleToHost (dat);
}

static inline unsigned __LongSwap (unsigned dat)
{
	return CFSwapInt32LittleToHost (dat);
}

#define ShortSwap __ShortSwap
#define LongSwap __LongSwap
