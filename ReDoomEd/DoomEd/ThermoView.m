// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "ThermoView.h"

@implementation ThermoView

- setThermoWidth:(int)current max:(int)maximum
{
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'bounds' as an instance var, fake it using a local
	NSRect bounds = [self bounds];
#endif

	thermoWidth = bounds.size.width*((CGFloat)current/(CGFloat)maximum);
	return self;
}

- drawSelf:(const NXRect *)rects :(int)rectCount
{
#ifdef REDOOMED
	// Cocoa compatibility: can no longer access 'bounds' as an instance var, fake it using a local
	NSRect bounds = [self bounds];
#endif

	PSsetlinewidth(bounds.size.height);

	PSsetrgbcolor(0.5,1.0,1.0);
	PSmoveto(0,bounds.size.height/2);
	PSlineto(thermoWidth,bounds.size.height/2);
	PSstroke();
	
	PSsetgray(0.5);
	PSmoveto(thermoWidth+1,bounds.size.height/2);
	PSlineto(bounds.size.width,bounds.size.height/2);
	PSstroke();

	return self;
}

@end
