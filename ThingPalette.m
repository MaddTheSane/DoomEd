#import "ThingPalette.h"
#import "ThingPalView.h"
#import	"DoomProject.h"
#import	"TextureEdit.h"
#import	"Wadfile.h"
#import	"lbmfunctions.h"

ThingPalette *thingPalette_i;

@implementation ThingPalette


//============================================================
//
//	Initialization
//
//============================================================
- init
{
	if (self = [super init]) {
	thingPalette_i = self;
	window_i = nil;
	thingImages = NULL;
	currentIcon = -1;
	}
	return self;
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
			@"You haven't grabbed any icons!",
			@"OK", nil, nil);
		return;
	}

	if (!window_i)
	{
		[NSBundle loadNibNamed: @"ThingPalette"
						 owner: self];

		[window_i	setDelegate:self];
		[self		computeThingDocView];
		[nameField_i	setStringValue:@""];
	}

	[window_i	makeKeyAndOrderFront:self];
}

//============================================================
//
//	Find icon from name.  Returns index or -1 if not found.
//
//============================================================
- (int)findIcon:(char *)name
{
	int		i;
	int		max;
	icon_t	*icon;
	
	max = [thingImages	count];
	for (i = 0;i < max;i++)
	{
		icon = [thingImages	elementAt:i];
		if (!strcasecmp(icon->name,name))
			return i;
	}
	
	return -1;
}

//============================================================
//
//	Return icon data
//
//============================================================
- (icon_t *)getIcon:(int)which
{
	return [thingImages	elementAt:which];
}

//============================================================
//
//	Return currently selected icon #
//
//============================================================
@synthesize currentIcon;
- (int)getCurrentIcon
{
	return self.currentIcon;
}

//============================================================
//
//	Set currently selected icon #
//
//============================================================
- (void)setCurrentIcon:(int)which
{
	icon_t	*icon;
	NSRect	r;
	
	if (which < 0)
		return;
		
	currentIcon = which;
	icon = [thingImages	elementAt:which];
	[nameField_i		setStringValue:@(icon->name)];
	r = icon->r;
	r.origin.y -= SPACING;
	r.size.height += SPACING*2;
	[thingPalView_i		scrollRectToVisible:r];
	//[thingPalScrView_i	display];
}

//============================================================
//
//	Return amount of icons available
//
//============================================================
- (int)getNumIcons
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
	int		i;
	int		max;
	icon_t	*icon;
	
	max = [thingImages	count];
	for (i = 0; i < max; i++)
	{
		icon = [thingImages	elementAt:i];
		if (icon->image != NULL) {
			[icon->image release];
			icon->image = nil;
		}
	}
	[thingImages	empty];
}

//============================================================
//
//	Set coords for all icons in the thingPalView
//
//============================================================
- (void)computeThingDocView
{
	NSRect	dvr;
	int		i;
	int		x;
	int		y;
	int		max;
	icon_t	*icon;
	int		maxwidth;
	NSPoint	p;
	
	dvr = [thingPalScrView_i documentVisibleRect];
	max = [thingImages	count];
	maxwidth = ICONSIZE*5 + SPACING*5;

	//
	//	Calculate the size of docView we're gonna need... 
	//
	x = y = SPACING;
	for (i = 0; i < max; i++)
	{
		icon = [thingImages	elementAt:i];
		
		if (icon->image == NULL)
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
	
	[thingPalView_i	setFrameSize:NSMakeSize(dvr.size.width, y)];
	p.x = 0;
	p.y = y + ICONSIZE + SPACING;
	x = SPACING;

	//
	//	The docView has been resized. Now go and reorder all
	//	the flats from top to bottom...
	//
	for (i = 0; i < max; i++)
	{
		icon = [thingImages	elementAt:i];
		if (icon->image == NULL)
		{
			x = SPACING;
			y -= ICONSIZE + SPACING;
			icon->r.origin.x = x;
			icon->r.origin.y = y;
			y -= ICONSIZE/2 + SPACING;
			continue;
		}
		
		if (x > maxwidth )
		{
			x = SPACING;
			y -= ICONSIZE + SPACING;
		}
		icon->r.origin.x = x;
		icon->r.origin.y = y;
		x += ICONSIZE + SPACING;
	}
	
	[thingPalView_i	scrollPoint:p ];
}

//==========================================================
//
//	Load in and init thingImages
//
//==========================================================
- (void)initIcons
{
	int		start;
	int		end;
	int		i;
	unsigned short	shortpal[256];
	unsigned char 	*palLBM;
	patch_t	*iconvga;
	icon_t	icon;
//	id		panel;

#if 0
	panel = NSGetAlertPanel(@"One moment...",
			@"Loading icons for Thing Palette.",
			nil, nil, nil);
	[panel	orderFront:NULL];
	[panel	flushWindow];
	PSwait();
#endif
	
	//
	//	Get palette and convert to 16-bit
	//
	palLBM = [wadfile_i	loadLumpNamed:"playpal"];
	if (palLBM == NULL)
		IO_Error ("Need to have 'playpal' palette in .WAD file!");
	LBMpaletteTo16 (palLBM, shortpal);

	thingImages = [[CompatibleStorage alloc]
		initCount: 0
		elementSize: sizeof(icon_t)
		description: NULL
	];

	//
	// get inclusive lump #'s for patches
	//
	start = [wadfile_i	lumpNamed:"icon_sta"] + 1;
	end = [wadfile_i	lumpNamed:"icon_end"];
	[doomproject_i	initThermo:@"One moment..."
		message:@"Loading icons for Thing Palette."];

	if  (start == -1 || end == -1 )
	{
		[doomproject_i	closeThermo];
		return;		// no icons, no problem.
	}
			
	for (i = start; i < end; i++)
	{
		[doomproject_i	updateThermo:i-start max:end-start];
		//
		// load icon patch255 and convert to an NXImage
		//
		bzero(&icon,sizeof(icon));
		iconvga = [wadfile_i	loadLump:i];
		strcpy(icon.name,[wadfile_i	lumpname:i]);
		icon.name[8] = 0;
		strupr(icon.name);
		if (!strncmp(icon.name,"I-",2))
		{
			[thingImages	addElement:&icon];
			free(iconvga);
			continue;
		}

		icon.image = patchToImage(iconvga,shortpal,&icon.imagesize,icon.name);
		icon.r.size.width = ICONSIZE;
		icon.r.size.height = ICONSIZE;
		[thingImages	addElement:&icon];
		free(iconvga);
	}
	
	free(palLBM);
	[doomproject_i	closeThermo];
}

@end
