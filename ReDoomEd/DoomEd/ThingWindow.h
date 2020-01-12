// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

#ifdef REDOOMED
// switched parent class to NSPanel to make Thing Inspector a floating panel
@interface ThingWindow:NSPanel
#else // Original
@interface ThingWindow:Window
#endif
{
	id	parent_i;
	char	string[32];
}

- setParent:(id)p;


@end
