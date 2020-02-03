// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

typedef struct
{
	NXRect	r;
	NXSize	imagesize;
	char	name[10];
	id		image;
} icon_t;

#define	SPACING		10
#define	ICONSIZE	48

@class Storage;
@class ThingPalView;
@class ThingPalette;
extern ThingPalette *thingPalette_i;

@interface ThingPalette:NSObject <NSWindowDelegate>
{
	IBOutlet NSPanel		*window_i;			// outlet
	IBOutlet ThingPalView	*thingPalView_i;	// outlet
	IBOutlet NSScrollView	*thingPalScrView_i;	// outlet
	IBOutlet NSTextField	*nameField_i;		// outlet
	
	Storage	*thingImages;		// Storage for icons
	int		currentIcon;		// currently selected icon
}

- (IBAction)menuTarget:sender;
- (NSInteger)findIcon:(const char *)name;
- (icon_t *)getIcon:(NSInteger)which;
@property (nonatomic) int currentIcon;
- (int)getCurrentIcon API_DEPRECATED_WITH_REPLACEMENT("-currentIcon", macos(10.0, 10.0));
- (int)countOfIcons;
- (void)computeThingDocView;
- (void)initIcons;
- (void)dumpAllIcons;


@end
