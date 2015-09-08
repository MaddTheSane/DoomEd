#import <appkit/appkit.h>

@interface PopScrollView : NSScrollView
{
	id	button1, button2;
}

- (instancetype)initWithFrame:(NSRect)frameRect button1: b1 button2: b2;
- (void)tile;

@end
