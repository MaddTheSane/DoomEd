#import "Storage.h"

#import <appkit/appkit.h>

typedef struct
{
	int		value;
	char		desc[32];
} thingstrip_t;

#define	THINGSTRIPNAME	@"ThingStripper"

@interface ThingStripper:NSObject
{
	IBOutlet id	thingBrowser_i;		// nib outlets
	IBOutlet id	thingStripPanel_i;

	CompatibleStorage *thingList_i;
}

- (IBAction)displayPanel:sender;
- (IBAction)addThing:sender;
- (IBAction)deleteThing:sender;
- (IBAction)doStrippingAllMaps:sender;
- (IBAction)doStrippingOneMap:sender;

@end
