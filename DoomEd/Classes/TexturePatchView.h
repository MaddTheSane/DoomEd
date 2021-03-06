#import "Storage.h"

#import <AppKit/AppKit.h>

#ifndef	H_DIVIDERT
#define	H_DIVIDERT
typedef struct
{
	int		x,y;
	char		string[32];
} divider_t;
#endif

@interface TexturePatchView:NSView
{
	CompatibleStorage *dividers_i;
}

- (void)addDividerX:(int)x Y:(int)y String:(char *)string;
- (void)dumpDividers;

@end
