#import "Storage.h"

#import <AppKit/AppKit.h>

typedef struct
{
	int		value;
	char		desc[32];
} thingstrip_t;

#define	THINGSTRIPNAME	@"ThingStripper"

@interface ThingStripper:NSObject <NSWindowDelegate, NSBrowserDelegate>
{
	IBOutlet NSBrowser	*thingBrowser_i;		// nib outlets
	IBOutlet NSWindow	*thingStripPanel_i;

	CompatibleStorage *thingList_i;
}

- (IBAction)displayPanel:sender;
- (IBAction)addThing:sender;
- (IBAction)deleteThing:sender;
- (IBAction)doStrippingAllMaps:sender;
- (IBAction)doStrippingOneMap:sender;

@end
