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

@class ThingPalette;
extern ThingPalette *thingPalette_i;

@interface ThingPalette:Object
{
	IBOutlet id		window_i;			// outlet
	IBOutlet id		thingPalView_i;		// outlet
	IBOutlet id		thingPalScrView_i;	// outlet
	IBOutlet id		nameField_i;		// outlet
	
	id		thingImages;		// Storage for icons
	int		currentIcon;		// currently selected icon
}

- (IBAction)menuTarget:sender;
- (int)findIcon:(char *)name;
- (icon_t *)getIcon:(int)which;
@property (nonatomic) int currentIcon;
- (int)getCurrentIcon API_DEPRECATED_WITH_REPLACEMENT("-currentIcon", macos(10.0, 10.0));
- (int)getNumIcons;
- computeThingDocView;
- initIcons;
- dumpAllIcons;


@end
