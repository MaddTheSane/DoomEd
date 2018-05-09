
#import <AppKit/AppKit.h>

@class Coordinator;
extern Coordinator *coordinator_i;

extern	BOOL	debugflag;

#define	TOOLNAME	@"ToolPanel"

@interface Coordinator:NSObject <NSApplicationDelegate>
{
	IBOutlet NSPanel	*toolPanel_i;
	IBOutlet NSPanel	*infoPanel_i;
}

- (IBAction)toggleDebug: sender;
- (IBAction)redraw: sender;
@end
