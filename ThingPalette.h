#import "Storage.h"

#import <AppKit/AppKit.h>

typedef struct
{
	NSRect	r;
	NSSize	imagesize;
	char	name[10];
	NSImage	*image;
} icon_t;

@class ThingPalView;

#define	SPACING		10
#define	ICONSIZE	48

@interface ThingPalette:NSObject <NSWindowDelegate>
{
	IBOutlet NSWindow		*window_i;			// outlet
	IBOutlet ThingPalView	*thingPalView_i;	// outlet
	IBOutlet NSScrollView	*thingPalScrView_i;	// outlet
	IBOutlet NSTextField	*nameField_i;		// outlet

	CompatibleStorage *thingImages;		// Storage for icons
	int		currentIcon;		// currently selected icon
}

- (IBAction)menuTarget:sender;
- (int)findIcon:(char *)name;
- (icon_t *)getIcon:(int)which;
@property (nonatomic) int currentIcon;
- (int)getCurrentIcon DEPRECATED_MSG_ATTRIBUTE("Use currentIcon instead");
- (int)getNumIcons;
- (void)computeThingDocView;
- (void)initIcons;
- (void)dumpAllIcons;


@end

extern ThingPalette *thingPalette_i;


