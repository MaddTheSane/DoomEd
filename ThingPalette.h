#import "Storage.h"

#import <appkit/appkit.h>

typedef struct
{
	NSRect	r;
	NSSize	imagesize;
	char	name[10];
	NSImage	*image;
} icon_t;

#define	SPACING		10
#define	ICONSIZE	48

@interface ThingPalette:NSObject
{
	IBOutlet id		window_i;			// outlet
	IBOutlet id		thingPalView_i;		// outlet
	IBOutlet id		thingPalScrView_i;	// outlet
	IBOutlet id		nameField_i;		// outlet

	CompatibleStorage *thingImages;		// Storage for icons
	int		currentIcon;		// currently selected icon
}

- (IBAction)menuTarget:sender;
- (int)findIcon:(char *)name;
- (icon_t *)getIcon:(int)which;
- (int)getCurrentIcon;
- (void)setCurrentIcon:(int)which;
- (int)getNumIcons;
- (void)computeThingDocView;
- (void)initIcons;
- (void)dumpAllIcons;


@end

extern ThingPalette *thingPalette_i;


