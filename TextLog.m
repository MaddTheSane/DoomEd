
#import "TextLog.h"

@implementation TextLog

//======================================================
//
//	TextLog Class
//
//	Simply lets you send a bunch of strings to a list (for errors and status info)
//
//======================================================

- initWithTitle: (NSString *) title
{
	window_i = [[NSBundle mainBundle] loadNibNamed: @"TextLog.nib"
		owner: self
		options: nil
	];
	[window_i setTitle: title];
	return self;
}

- (void)msg:(char *)string
{
	int		len;

	len = [text_i textLength];
	[text_i setSel:len :len];
	[text_i replaceSel:string];
	[text_i	scrollSelToVisible];
}

- (IBAction)display:sender
{
	[window_i	makeKeyAndOrderFront:sender];
}

- (IBAction)clear:sender
{
	int		len;

	len = [text_i textLength];
	[text_i setSel:0 :len];
	[text_i replaceSel:"\0"];
}

@end
