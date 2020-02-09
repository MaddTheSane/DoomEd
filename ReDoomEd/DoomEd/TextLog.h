// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@interface TextLog:NSObject
{
	IBOutlet NSTextView	*text_i;
	IBOutlet NSWindow	*window_i;
}

#ifdef REDOOMED
// declare initTitle: publicly
- initTitle:(char *)title API_DEPRECATED_WITH_REPLACEMENT("-initWithTitle:", macos(10.0, 10.0));
- (instancetype)initWithTitle:(NSString*)title;
#endif

- (void)addMessage:(NSString*)string;
- (void)addFormattedMessage:(NSString*)string, ... NS_FORMAT_FUNCTION(1,2);
- (IBAction)display:(id)sender;
- (IBAction)clear:(id)sender;

@end
