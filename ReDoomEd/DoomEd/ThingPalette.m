// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "ThingPalette.h"
#import	"DoomProject.h"
#import	"TextureEdit.h"
#import	"Wadfile.h"
#import	"lbmfunctions.h"

id	thingPalette_i;

@implementation ThingPalette


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
	thingImages = window_i = NULL;
	currentIcon = -1;
	return self;
}

//============================================================
//
//	Menu target
//
//============================================================
- menuTarget:sender
{
	if (![thingImages	count])
	{
		NXRunAlertPanel("Nope!",
			"You haven't grabbed any icons!","OK",NULL,NULL);
		return self;
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
	
	return self;
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
- (int)getCurrentIcon
{
	return currentIcon;
}

@synthesize currentIcon;

//============================================================
//
//	Set currently selected icon #
//
//============================================================
- (void)setCurrentIcon:(int)which
{
	icon_t	*icon;
	NXRect	r;
	
	if (which < 0)
		return;
		
	currentIcon = which;
	icon = [thingImages	elementAt:which];

#ifdef REDOOMED
	[nameField_i		setStringValue:RDE_NSStringFromCString(icon->name)];
#else // Original
	[nameField_i		setStringValue:icon->name];
#endif

	r = icon->r;
	r.origin.y -= SPACING;
	r.size.height += SPACING*2;

#ifdef REDOOMED
	// Cocoa's scrollRectToVisible: takes a value, not a pointer
	[thingPalView_i		scrollRectToVisible:r];
#else // Original
	[thingPalView_i		scrollRectToVisible:&r];
#endif

	[thingPalScrView_i	display];
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
- dumpAllIcons
{
	int		i;
	int		max;
	icon_t	*icon;
	
	max = [thingImages	count];
	for (i = 0; i < max; i++)
	{
		icon = [thingImages	elementAt:i];
		if (icon->image != NULL)
			free(icon->image);
	}
	[thingImages	empty];
	
	return self;
}

//============================================================
//
//	Set coords for all icons in the thingPalView
//
//============================================================
- computeThingDocView
{
	NXRect	dvr;
	int		i;
	int		x;
	int		y;
	int		max;
	icon_t	*icon;
	int		maxwidth;
	NXPoint	p;
	
	[thingPalScrView_i	getDocVisibleRect:&dvr];
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
	
	[thingPalView_i	sizeTo:dvr.size.width	:y];
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
	
#ifdef REDOOMED
	// Cocoa's scrollPoint: takes a value, not a pointer
	[thingPalView_i	scrollPoint:p ];
#else // Original	
	[thingPalView_i	scrollPoint:&p ];
#endif

	return self;
}

//==========================================================
//
//	Load in and init thingImages
//
//==========================================================
- initIcons
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

	thingImages = [[Storage	alloc]
				initCount:		0
				elementSize:	sizeof(icon_t)
				description:	NULL];
		
	//
	// get inclusive lump #'s for patches
	//
	start = [wadfile_i	lumpNamed:"icon_sta"] + 1;
	end = [wadfile_i	lumpNamed:"icon_end"];
	[doomproject_i	initThermo:"One moment..."
		message:"Loading icons for Thing Palette."];

	if  (start == -1 || end == -1 )
	{
		[doomproject_i	closeThermo];
		return self;		// no icons, no problem.
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
	
	return 0;
}

@end
