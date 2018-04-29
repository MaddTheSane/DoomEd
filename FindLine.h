
#import <AppKit/AppKit.h>

@interface FindLine: NSObject
{
	IBOutlet NSWindow		*window_i;
	IBOutlet NSTextField	*status_i;
	IBOutlet NSTextField	*numfield_i;
	NSSound *delSound;
	IBOutlet NSButton		*fromBSP_i;
}

#define MARGIN		64			// margin from window edge
#define	PREFNAME	@"FindLinePanel"

- (int)getRealLineNum:(int)num;
- (IBAction)findLine:sender;
- (IBAction)deleteLine:sender;
- (IBAction)menuTarget:sender;
- (void)rectFromPoints:(NSRect *)r p1:(NSPoint)p1 p2:(NSPoint)p2;

@end
