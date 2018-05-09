#import "ps_quartz.h"

#import "ThermoView.h"

@implementation ThermoView

- (void)setThermoWidth:(int)current max:(int)maximum
{
	thermoWidth = [self bounds].size.width*((CGFloat)current/(CGFloat)maximum);
}

- (void)drawRect:(NSRect)rects
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	path.lineWidth = self.bounds.size.height;

	[[NSColor colorWithRed:0.5 green:1 blue:1 alpha:1] set];
	[path moveToPoint:NSMakePoint(0, [self bounds].size.height/2)];
	[path lineToPoint:NSMakePoint(thermoWidth, [self bounds].size.height/2)];
	[path stroke];
	
	[path removeAllPoints];
	
	[[NSColor grayColor] set];
	[path moveToPoint:NSMakePoint(thermoWidth+1, [self bounds].size.height/2)];
	[path lineToPoint:NSMakePoint([self bounds].size.width, [self bounds].size.height/2)];
	[path stroke];
}

@end
