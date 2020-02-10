// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif
#import "RDEPatchDivider.h"

#ifndef	H_DIVIDERT
#define	H_DIVIDERT
typedef struct
{
	int		x,y;
	char		string[32];
} divider_t;
#endif

@class Storage;

@interface FlatsView:View <RDEPatchDivider>
{
	Storage	*dividers_i;
}

- (void)addDividerX:(int)x Y:(int)y String:(const char *)string;
- (void)dumpDividers;

@end
