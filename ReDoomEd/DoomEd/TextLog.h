// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@interface TextLog:Object
{
	id	text_i;
	id	window_i;
}

#ifdef REDOOMED
// declare initTitle: publicly
- initTitle:(char *)title;
#endif

- msg:(char *)string;
- display:sender;
- clear:sender;

@end
