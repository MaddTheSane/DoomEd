
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
	if (self = [super init]) {
		[NSBundle loadNibNamed: @"TextLog"
						 owner: self];
		[window_i setTitle: title];
	}
	return self;
}

- (void)addLogString:(NSString*)string
{
	NSAttributedString *tmpAttr = [[NSAttributedString alloc] initWithString:string];
	[self addLogAttributedString:tmpAttr];
	[tmpAttr release];
}

- (void)addLogAttributedString:(NSAttributedString*)string
{
	[text_i.textStorage beginEditing];
	[text_i.textStorage appendAttributedString:string];
	[text_i.textStorage endEditing];
	[text_i.enclosingScrollView scrollToEndOfDocument:nil];
}

- (void)msg:(char *)string
{
	[self addLogString:@(string)];
}

- (IBAction)display:sender
{
	[window_i makeKeyAndOrderFront:sender];
}

- (IBAction)clear:sender
{
	[text_i.textStorage beginEditing];
	[text_i.textStorage setAttributedString:[[[NSAttributedString alloc] init] autorelease]];
	[text_i.textStorage endEditing];
}

@end
