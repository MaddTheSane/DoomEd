
#import "Storage.h"
#import <appkit/appkit.h>

#if 0
typedef struct
{
	int		x,y;
	char		string[32];
} divider_t;
#endif

@interface TexturePalView:NSView
{
	CompatibleStorage *dividers_i;
}

- (void)addDividerX:(int)x Y:(int)y String:(char *)string;
- (void)dumpDividers;

@end
