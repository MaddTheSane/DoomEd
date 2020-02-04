// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@interface FindLine:NSObject
{
	IBOutlet NSPanel	*window_i;
	IBOutlet NSTextField *status_i;
	IBOutlet NSTextField *numfield_i;
	NSSound	*delSound;
	IBOutlet NSButton	*fromBSP_i;
}

#define MARGIN		64			// margin from window edge

#ifdef REDOOMED
#   define	PREFNAME	@"FindLinePanel"
#else // Original
#   define	PREFNAME	"FindLinePanel"
#endif

- (NSInteger)getRealLineNum:(int)num;
- (IBAction)findLine:sender;
- (IBAction)deleteLine:sender;
- (IBAction)menuTarget:sender;
- (void)rectFromPoints:(NXRect *)r p1:(NXPoint)p1 p2:(NXPoint)p2;

@end
