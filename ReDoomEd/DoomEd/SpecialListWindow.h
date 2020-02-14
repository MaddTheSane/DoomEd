// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

#ifdef REDOOMED
// switched parent class to NSPanel to make Line Specials & Sector Specials into floating panels
@interface SpecialListWindow:NSPanel
#else // Original
@interface SpecialListWindow:Window
#endif
{
	__unsafe_unretained id	parent_i;
	char	string[32];
}

- (void)setParent:(id)p;

@end
