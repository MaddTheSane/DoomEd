// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@interface ThermoView:View
{
	CGFloat		thermoWidth;
}

- setThermoWidth:(int)current max:(int)maximum;

@end
