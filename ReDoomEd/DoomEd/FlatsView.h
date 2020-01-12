// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

#ifndef	H_DIVIDERT
#define	H_DIVIDERT
typedef struct
{
	int		x,y;
	char		string[32];
} divider_t;
#endif

@class Storage;

@interface FlatsView:View
{
	Storage	*dividers_i;
}

- addDividerX:(int)x Y:(int)y String:(char *)string;
- dumpDividers;

@end
