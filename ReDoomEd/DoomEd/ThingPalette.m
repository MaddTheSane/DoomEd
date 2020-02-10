// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "ThingPalette.h"
#import	"DoomProject.h"
#import	"TextureEdit.h"
#import	"Wadfile.h"
#import	"lbmfunctions.h"
#import "ThingPalView.h"

@implementation ThingPaletteIcon

- (instancetype)init
{
	self = [super init];
	if (self) {
		self.name = @"";
	}
	return self;
}

- (void)dealloc
{
	[_name release];
	[_image release];
	
	[super dealloc];
}

@end

id	thingPalette_i;

@implementation ThingPalette {
	NSMutableArray<ThingPaletteIcon*>	*thingImages;		// Storage for icons
	NSInteger		currentIcon;		// currently selected icon
}

//============================================================
//
//	Initialization
//
//============================================================
- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	thingPalette_i = self;
	thingImages = nil; window_i = NULL;
	currentIcon = -1;
	return self;
}

- (void)dealloc
{
	[thingImages release];
	
	[super dealloc];
}

//============================================================
//
//	Menu target
//
//============================================================
- (IBAction)menuTarget:sender
{
	if (![thingImages	count])
	{
		NSRunAlertPanel(@"Nope!",
			@"You haven't grabbed any icons!",@"OK",NULL,NULL);
		return;
	}

	if (!window_i)
	{
		[NXApp 
			loadNibSection:	"ThingPalette.nib"
			owner:			self
			withNames:		NO
		];
		
		[window_i	setDelegate:self];
		[self		computeThingDocView];

#ifdef REDOOMED
		[nameField_i	setStringValue:@""];
#else // Original
		[nameField_i	setStringValue:""];
#endif
	}

	[window_i	makeKeyAndOrderFront:self];
}

/// Find icon from name.  Returns index or \c NSNotFound if not found.
- (NSInteger)findIcon:(NSString *)name
{
	NSInteger	i;
	NSInteger	max;
	ThingPaletteIcon *icon;
	
	max = [thingImages	count];
	for (i = 0;i < max;i++)
	{
		icon = [thingImages	objectAtIndex:i];
		if ([name caseInsensitiveCompare:icon.name] == NSOrderedSame)
			return i;
	}
	
	return NSNotFound;
}

//============================================================
//
//	Return icon data
//
//============================================================
- (ThingPaletteIcon *)getIcon:(NSInteger)which
{
	return [thingImages	objectAtIndex:which];
}

//============================================================
//
//	Return currently selected icon #
//
//============================================================

@synthesize currentIcon;

//============================================================
//
//	Set currently selected icon #
//
//============================================================
- (void)setCurrentIcon:(NSInteger)which
{
	ThingPaletteIcon	*icon;
	NXRect	r;
	
	if (which < 0 || which == NSNotFound)
		return;
		
	currentIcon = which;
	icon = [thingImages	objectAtIndex:which];

#ifdef REDOOMED
	[nameField_i		setStringValue:icon.name];
#else // Original
	[nameField_i		setStringValue:icon->name];
#endif

	r = icon.r;
	r.origin.y -= SPACING;
	r.size.height += SPACING*2;

#ifdef REDOOMED
	// Cocoa's scrollRectToVisible: takes a value, not a pointer
	[thingPalView_i		scrollRectToVisible:r];
#else // Original
	[thingPalView_i		scrollRectToVisible:&r];
#endif

	[thingPalScrView_i setNeedsDisplay:YES];
}

//============================================================
//
//	Return amount of icons available
//
//============================================================
- (NSInteger)countOfIcons
{
	return [thingImages	count];
}

//============================================================
//
//	Dump all icons
//
//============================================================
- (void)dumpAllIcons
{
	[thingImages removeAllObjects];
}

//============================================================
//
//	Set coords for all icons in the thingPalView
//
//============================================================
- (void)computeThingDocView
{
	NXRect	dvr;
	int		i;
	int		x;
	int		y;
	NSInteger		max;
	ThingPaletteIcon	*icon;
	int		maxwidth;
	NXPoint	p;
	
	dvr = thingPalScrView_i.documentVisibleRect;
	max = [thingImages	count];
	maxwidth = ICONSIZE*5 + SPACING*5;

	//
	//	Calculate the size of docView we're gonna need... 
	//
	x = y = SPACING;
	for (i = 0; i < max; i++)
	{
		icon = [thingImages	objectAtIndex:i];
		
		if (icon.image == nil)
		{
			x = SPACING;
			y += ICONSIZE + ICONSIZE/2 + SPACING*2;
			continue;
		}
		
		if (x > maxwidth)
		{
			x = SPACING;
			y += ICONSIZE + SPACING;
		}
		x += ICONSIZE + SPACING;
	}
	
	[thingPalView_i setFrameSize:NSMakeSize(dvr.size.width, y)];
	p.x = 0;
	p.y = y + ICONSIZE + SPACING;
	x = SPACING;

	//
	//	The docView has been resized. Now go and reorder all
	//	the flats from top to bottom...
	//
	for (i = 0; i < max; i++)
	{
		NSRect r;
		icon = [thingImages	objectAtIndex:i];
		if (icon.image == NULL)
		{
			x = SPACING;
			y -= ICONSIZE + SPACING;
			r = icon.r;
			r.origin = NSMakePoint(x, y);
			icon.r = r;
			y -= ICONSIZE/2 + SPACING;
			continue;
		}
		
		if (x > maxwidth )
		{
			x = SPACING;
			y -= ICONSIZE + SPACING;
		}
		r = icon.r;
		r.origin = NSMakePoint(x, y);
		icon.r = r;
		x += ICONSIZE + SPACING;
	}
	
#ifdef REDOOMED
	// Cocoa's scrollPoint: takes a value, not a pointer
	[thingPalView_i	scrollPoint:p ];
#else // Original	
	[thingPalView_i	scrollPoint:&p ];
#endif
}

//==========================================================
//
//	Load in and init thingImages
//
//==========================================================
- (void)initIcons
{
	NSInteger		start;
	NSInteger		end;
	NSInteger		i;
	unsigned short	shortpal[256];
	unsigned char 	*palLBM;
	patch_t	*iconvga;
//	id		panel;
	
#if 0
	panel = NXGetAlertPanel("One moment...",
			"Loading icons for Thing Palette.",NULL,NULL,NULL);
	[panel	orderFront:NULL];
	[panel	flushWindow];
	NXPing();
#endif
	
	//
	//	Get palette and convert to 16-bit
	//
	palLBM = [wadfile_i	loadLumpNamed:"playpal"];
	if (palLBM == NULL)
		IO_Error ("Need to have 'playpal' palette in .WAD file!");
	LBMpaletteTo16 (palLBM, shortpal);

	thingImages = [[NSMutableArray alloc] init];
		
	//
	// get inclusive lump #'s for patches
	//
	start = [wadfile_i	lumpNamed:"icon_sta"];
	end = [wadfile_i	lumpNamed:"icon_end"];
	[doomproject_i	initThermo:"One moment..."
		message:"Loading icons for Thing Palette."];

	if  (start == NSNotFound || end == NSNotFound )
	{
		[doomproject_i	closeThermo];
		return;		// no icons, no problem.
	}
			
	for (i = start+1; i < end; i++)
	@autoreleasepool {
		ThingPaletteIcon *icon = [[ThingPaletteIcon alloc] init];
		[doomproject_i	updateThermo:i-start max:end-start];
		//
		// load icon patch255 and convert to an NXImage
		//
		char	tmpname[10];
		iconvga = [wadfile_i	loadLump:i];
		strcpy(tmpname,[wadfile_i	lumpname:i]);
		tmpname[8] = 0;
		strupr(tmpname);
		icon.name = @(tmpname);
		if (!strncmp(tmpname,"I-",2))
		{
			[thingImages	addObject:icon];
			[icon release];
			free(iconvga);
			continue;
		}

		NSSize	tmpSize;
		icon.image = patchToImage(iconvga,shortpal,&tmpSize,icon.name.UTF8String);
		icon.imageSize = tmpSize;
		NSRect r = NSZeroRect;
		r.size = NSMakeSize(ICONSIZE, ICONSIZE);
		icon.r = r;
		[thingImages addObject:icon];
		[icon release];
		free(iconvga);
	}
	
	free(palLBM);
	[doomproject_i	closeThermo];
}

@end
