// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

#if 0
typedef struct
{
	int		x,y;
	char		string[32];
} divider_t;
#endif

@interface TexturePalView:View
{
	id	dividers_i;
}

- addDividerX:(int)x Y:(int)y String:(char *)string;
- dumpDividers;

@end
