
#import <appkit/appkit.h>

@interface TextLog:NSObject
{
	IBOutlet NSTextView	*text_i;
	IBOutlet NSPanel	*window_i;
}

- (instancetype)initWithTitle: (NSString *) title;
- (void)msg:(char *)string;
- (IBAction)display:sender;
- (IBAction)clear:sender;

@end
