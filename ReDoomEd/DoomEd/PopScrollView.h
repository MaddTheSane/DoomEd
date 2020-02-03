// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@interface PopScrollView : ScrollView
{
	__unsafe_unretained NSButton *button1, *button2;
}

- (id)initFrame:(const NXRect *)frameRect button1: b1 button2: b2 API_DEPRECATED_WITH_REPLACEMENT("-initWithFrame:button1:button2:", macos(10.0, 10.0));

- (instancetype)initWithFrame:(NSRect)frameRect button1:(NSButton*)b1 button2:(NSButton*)b2;

#ifdef REDOOMED
// Cocoa version
- (void) tile;
#else // Original
- tile;
#endif

@end
