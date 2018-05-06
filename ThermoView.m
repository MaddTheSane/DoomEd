#import "ps_quartz.h"

#import "ThermoView.h"

@implementation ThermoView

- (void)setThermoWidth:(int)current max:(int)maximum
{
	thermoWidth = [self bounds].size.width*((CGFloat)current/(CGFloat)maximum);
}

- (void)drawRect:(NSRect)rects
{
	PSsetlinewidth([self bounds].size.height);

	PSsetrgbcolor(0.5,1.0,1.0);
	PSmoveto(0,[self bounds].size.height/2);
	PSlineto(thermoWidth,[self bounds].size.height/2);
	PSstroke();
	
	PSsetgray(0.5);
	PSmoveto(thermoWidth+1,[self bounds].size.height/2);
	PSlineto([self bounds].size.width,[self bounds].size.height/2);
	PSstroke();
}

@end
