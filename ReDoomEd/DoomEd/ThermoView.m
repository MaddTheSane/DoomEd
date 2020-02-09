// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "ThermoView.h"

@implementation ThermoView

- (void)setThermoWidth:(NSInteger)current max:(NSInteger)maximum
{
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'bounds' as an instance var, fake it using a local
	NSRect bounds = [self bounds];
#endif

	thermoWidth = bounds.size.width*((CGFloat)current/(CGFloat)maximum);
	[self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)dirtyRect
{
	// Cocoa compatibility: can no longer access 'bounds' as an instance var, fake it using a local
	NSRect bounds = [self bounds];
	
	NSBezierPath *path = [NSBezierPath bezierPath];
	path.lineWidth = bounds.size.height;
	[[NSColor colorWithDeviceRed:0.5 green:1 blue:1 alpha:1] set];
	[path moveToPoint:NSMakePoint(0, bounds.size.height/2)];
	[path lineToPoint:NSMakePoint(thermoWidth, bounds.size.height/2)];
	[path stroke];
	
	path = [NSBezierPath bezierPath];
	path.lineWidth = bounds.size.height;
	[NSColor colorWithWhite:0.5 alpha:0.9];
	[path moveToPoint:NSMakePoint(thermoWidth+1,bounds.size.height/2)];
	[path lineToPoint:NSMakePoint(bounds.size.width,bounds.size.height/2)];
	[path stroke];
}

@end
