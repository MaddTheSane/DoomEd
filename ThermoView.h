
#import <AppKit/AppKit.h>

@interface ThermoView:NSView
{
	float		thermoWidth;
}

- (void)setThermoWidth:(int)current max:(int)maximum;

@end
