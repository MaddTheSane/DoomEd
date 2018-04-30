#import <appkit/appkit.h>

@interface PopScrollView : NSScrollView
{
	NSButton	*button1, *button2;
}

- (instancetype)initWithFrame:(NSRect)frameRect button1:(NSButton*) b1 button2:(NSButton*) b2;
- (void)tile;

@end
