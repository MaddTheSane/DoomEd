// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "TextLog.h"

@implementation TextLog

//======================================================
//
//	TextLog Class
//
//	Simply lets you send a bunch of strings to a list (for errors and status info)
//
//======================================================

- initTitle:(char *)title
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;

	// Bugfix: [NXApp loadNibSection:...] returns BOOL, not object
	[NXApp loadNibSection: "TextLog.nib"
	        owner: self
	        withNames: NO];
#else // Original
	window_i =	[NXApp 
				loadNibSection:	"TextLog.nib"
				owner:			self
				withNames:		NO
				];
#endif

#ifdef REDOOMED
	[window_i	setTitle:RDE_NSStringFromCString(title) ];
#else // Original
	[window_i	setTitle:title ];
#endif

	return self;
}

- msg:(char *)string
{
	int		len;

	len = [text_i textLength];
	[text_i setSel:len :len];
	[text_i replaceSel:string];
	[text_i	scrollSelToVisible];

	return self;
}

- display:sender
{
	[window_i	makeKeyAndOrderFront:NULL];
	return self;
}

- clear:sender
{
	int		len;

	len = [text_i textLength];
	[text_i setSel:0 :len];
	[text_i replaceSel:"\0"];

	return self;
}

@end
