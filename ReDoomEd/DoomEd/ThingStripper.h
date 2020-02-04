// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@class Storage;

typedef struct
{
	int		value;
	char		desc[32];
} thingstrip_t;

#ifdef REDOOMED
#   define	THINGSTRIPNAME	@"ThingStripper"
#else // Original
#   define	THINGSTRIPNAME	"ThingStripper"
#endif

@interface ThingStripper:NSObject <NSWindowDelegate>
{
	IBOutlet NSBrowser *thingBrowser_i;		// nib outlets
	IBOutlet NSWindow *thingStripPanel_i;

	Storage *thingList_i;
}

- (IBAction)displayPanel:sender;
- (IBAction)addThing:sender;
- (IBAction)deleteThing:sender;
- (IBAction)doStrippingAllMaps:sender;
- (IBAction)doStrippingOneMap:sender;

@end
