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
	return self = [self initWithTitle:RDE_NSStringFromCString(title)];
#else // Original
	window_i =	[NXApp 
				loadNibSection:	"TextLog.nib"
				owner:			self
				withNames:		NO
				];
	
	[window_i	setTitle:title ];

#endif

	return self;
}

#ifdef REDOOMED
- (instancetype)initWithTitle:(NSString*)title;
{
	if (self = [super init]) {
		[NSBundle loadNibNamed: @"TextLog_Cocoa" owner: self];
		
		[window_i setTitle:title];
	}
	return self;
}
#endif

- (void)addMessage:(NSString*)string
{
	NSInteger len = [text_i string].length;
	text_i.editable = YES;
	[text_i insertText:string replacementRange:NSMakeRange(len, 0)];
	text_i.editable = NO;
}

- (void)addFormattedMessage:(NSString *)string, ...
{
	va_list args;
	va_start(args, string);
	NSString *ourStr = [[NSString alloc] initWithFormat:string arguments:args];
	va_end(args);
	[self addMessage:ourStr];
	[ourStr release];
}

- (IBAction)display:(id)sender
{
	[window_i	makeKeyAndOrderFront:NULL];
}

- (IBAction)clear:(id)sender
{
    [text_i replaceCharactersInRange: NSMakeRange(0, text_i.string.length)
						  withString: @""];
}

@end
