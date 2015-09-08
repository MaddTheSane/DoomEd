
#import <appkit/appkit.h>

@interface TextLog:NSObject
{
	IBOutlet id	text_i;
	NSWindow *window_i;
}

- (instancetype)initWithTitle: (NSString *) title;
- (void)msg:(char *)string;
- (IBAction)display:sender;
- (IBAction)clear:sender;

@end
