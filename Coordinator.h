
#import <appkit/appkit.h>

extern	id	coordinator_i;

extern	BOOL	debugflag;

#define	TOOLNAME	@"ToolPanel"

@interface Coordinator:NSObject
{
	IBOutlet id	toolPanel_i;
	IBOutlet id	infoPanel_i;
	NSSound *startupSound_i;
}

- (IBAction)toggleDebug: sender;
- (IBAction)redraw: sender;
@end
