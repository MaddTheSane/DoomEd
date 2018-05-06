
#import <appkit/appkit.h>

@interface ThingWindow:NSWindow
{
	__unsafe_unretained id	parent_i;
	char	string[32];
}
@property (assign) id parent;


@end
