// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

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

@interface ThingStripper:Object
{
	IBOutlet id	thingBrowser_i;		// nib outlets
	IBOutlet id	thingStripPanel_i;

	id	thingList_i;
}

- (IBAction)displayPanel:sender;
- (IBAction)addThing:sender;
- (IBAction)deleteThing:sender;
- (IBAction)doStrippingAllMaps:sender;
- (IBAction)doStrippingOneMap:sender;

@end
