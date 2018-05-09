
#import "Storage.h"
#import <AppKit/AppKit.h>

typedef struct
{
	int	xoff,yoff;
	texpatch_t *p;
} delta_t;

@interface TextureView:NSView
{
	CompatibleStorage *deltaTable;
}


@end
