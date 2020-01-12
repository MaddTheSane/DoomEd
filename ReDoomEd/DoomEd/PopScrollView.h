// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@interface PopScrollView : ScrollView
{
	id	button1, button2;
}

- initFrame:(const NXRect *)frameRect button1: b1 button2: b2;

#ifdef REDOOMED
// Cocoa version
- (void) tile;
#else // Original
- tile;
#endif

@end
