
#import <AppKit/AppKit.h>

@interface ThermoView:NSView
{
	CGFloat		thermoWidth;
}

- (void)setThermoWidth:(int)current max:(int)maximum;

@end
