#import	"DoomProject.h"
#import	"TextureEdit.h"
#import	"TexturePalette.h"
#import	"TexturePalView.h"
#import	"lbmfunctions.h"
#import	"Wadfile.h"
#import	"TextLog.h"
#import "ps_quartz.h"

TexturePalette *texturePalette_i;

@implementation TexturePalette

- (instancetype)init
{
	if (self = [super init]) {
	window_i = NULL;
	texturePalette_i = self;
	selectedTexture = -1;

	allTextures = [[CompatibleStorage alloc]
		initCount: 0
		elementSize: sizeof(texpal_t)
		description: NULL
	];
	}

	return self;
}

- (void)saveFrame
{
	if (window_i)
		[window_i	saveFrameUsingName:@"TexturePalette"];
}

- (void)initTextures
{
	[self	createAllTextureImages];
	[self	finishInit];
}

- (void)finishInit
{
	NSPoint	p;
	NSRect	dvr;

	[self	computePalViewSize];
	//
	// start textures at top
	//
	dvr = [texturePalView_i frame];
	p.x = 0;
	p.y = dvr.size.height;
	[texturePalView_i scrollPoint:p];
}

- (void)setupPalette
{
	[self	finishInit];
	if ([allTextures	count])
		[self	selectTexture:0];
	[window_i	setFrameUsingName:@"TexturePalette"];
}

- (IBAction)menuTarget:sender
{
	if (![doomproject_i isLoaded])
	{
		NSRunAlertPanel(@"Oops!",
			@"There must be a project loaded before you even THINK about choosing textures!",
			@"OK", nil, nil, nil);
		return;
	}
		
	if (!window_i)
	{
		[NSBundle loadNibNamed: @"TexturePalette"
						 owner: self];

		[self setupPalette];
		[window_i	setDelegate:self];
	}

	[window_i	makeKeyAndOrderFront:NULL];
}

- (void)windowDidMiniaturize:(NSNotification *)notification
{
	NSWindow *window = [notification object];
	// TODO [window setMiniwindowIcon:"DoomEd"];
	[window setMiniwindowTitle:@"TxPalette"];
}


//
// create all the texture images for the palette
// NOTE: allTextures must have been created
//
- (void)createAllTextureImages
{
	int		j;
	texpal_t	t;
	
	[allTextures	empty];
	
	for (j = 0; j < numtextures; j++)
	{
		t = [self	createTextureImage:j];
		[allTextures	addElement:&t];
	}
}

//
// create a texture image from all its patches for the palette
// NOTE: allTextures must have been created
//
- (texpal_t) createTextureImage:(int)which
{
	int	i;
	texpal_t	t;
	NSSize	s;

	s.width = textures[which].width;
	s.height = textures[which].height;
	t.r = NSMakeRect(0, 0, 0, 0);
	t.r.size = s;
	t.WADindex = textures[which].WADindex;
	strcpy(t.name,textures[which].name);
	t.patchamount = textures[which].patchcount;
	t.image = [[NSImage alloc] initWithSize: s];
	[t.image lockFocus];
	//[t.image	 useCacheWithDepth:NX_TwelveBitRGBDepth];
	//[t.image	lockFocusOn:[t.image lastRepresentation]];

	[[NSColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0] set];
	NSRectFill(t.r);

	for (i = 0; i < textures[which].patchcount; i++)
	{
		texpatch_t	p;

		p.patchInfo = textures[which].patches[i];
		p.patch = [textureEdit_i getPatchImage:p.patchInfo.patchname];
		if (!p.patch)
		{
			NSRunAlertPanel(@"Shit!",
				@"While building texture #%d, I couldn't find "
				"the '%s' patch!",
				@"OK", nil, nil,
				i, p.patchInfo.patchname);
			[[NSApplication sharedApplication] terminate: nil];
		}
		p.r.origin.x = p.patchInfo.originx;
		p.r.origin.y = (textures[which].height) - 
					(p.patch->r.size.height) - 
					(p.patchInfo.originy);
		p.r.size.width = p.patch->r.size.width;
		p.r.size.height = p.patch->r.size.height;
		[p.patch->image	drawAtPoint:p.r.origin fromRect:NSZeroRect
		                operation:NSCompositeSourceOver fraction:1];
	}
	[t.image unlockFocus];
	return t;
}

//
// add/replace a texture image in palette
//
- (void)storeTexture:(int)which
{
	texpal_t	*t,tex;
	
	if ((![allTextures	count]) ||
		(which > [allTextures	count] - 1))
			[allTextures	addElement:&tex];
	else
	{
		t = [allTextures	elementAt:which];
		[t->image release];
		t->image = nil;
	}

	tex = [self	createTextureImage:which];
	[allTextures	replaceElementAt:which with:&tex];

	[self	computePalViewSize];
	[self	selectTexture:which];
	[doomproject_i setProjectDirty:TRUE];
}

//=========================================================
//
//	Compute size of texture palette view from amount of texture images in allTextures
//
//=========================================================
- (texpal_t *)getNewTexture:(int)which
{
	return	[newTextures	elementAt:which];
}

- (void)computePalViewSize
{
	texpal_t	*t, *t2;
	int			count,maxwidth,x,y;
	NSSize		s,imagesize;
	int			maxwindex, i, j;
	char		string[32];

	if (newTextures == nil )
		newTextures = [[CompatibleStorage alloc ]
			initCount: [allTextures  count]
			elementSize: sizeof(texpal_t)
			description: NULL
		];
	else
		[newTextures empty];

	maxwidth = 0;
	x = y = SPACING;
	count = [allTextures count] - 1;
	
	//
	//	See how many texture sets we have
	//
	maxwindex = 0;
	for (i = 0; i <= count; i++)
	{
		t = [allTextures	elementAt:i ];
		if (t->WADindex > maxwindex)
			maxwindex = t->WADindex;
	}
	
	//
	//	Build newTextures to hold texture sets in order
	//	from allTextures
	//
	for (i = 0; i <= maxwindex; i++)
		for (j = 0; j <= count; j++)
		{
			t = [allTextures	elementAt:j ];
			if (t->WADindex == i )
			{
				t->oldIndex = j;
				[newTextures	addElement: t ];
			}
		}

	//
	//	Compute Texture Palette size
	//
	[texturePalView_i dumpDividers];
	while (count >= 0)
	{
		t = [newTextures	elementAt:count];

		if (t->WADindex < maxwindex)
		{
			maxwindex = t->WADindex;
			sprintf (string, "Texture Set #%d", maxwindex+2 );
			y += SPACING;
			[texturePalView_i addDividerX: x
			                  Y: y
			                  String: string ];
			y += SPACING*2;
		}

		t->r.origin.x = x;
		t->r.origin.y = y;
		imagesize = t->image.size;
		if (imagesize.width > maxwidth)
			maxwidth = imagesize.width;

		t2 = [allTextures	elementAt:t->oldIndex ];
		t2->r.origin.x = x;
		t2->r.origin.y = y;

		y += imagesize.height + SPACING;

		count--;
	}

	s.width = maxwidth + SPACING*2;
	s.height = y;
	[texturePalView_i setFrameSize:s];
}

//
// return * to texture image[which]
//
- (texpal_t *)getTexture:(int)which
{
	return [allTextures	elementAt:which];
}

- (int)selectTextureNamed:(const char *)name
{
	texpal_t *t;
	int		i;
	int		max;
	NSRect	r;
	
	max = [allTextures	count ];
	for (i = 0; i < max; i++)
	{
		t = [allTextures	elementAt:i ];
		if ( !strcasecmp (name, t->name ) )
			break;
	}
	
	selectedTexture = i;
	t = [self	getTexture:i];
	[titleField_i	setStringValue:@(t->name)];
	[widthField_i	setIntValue:t->r.size.width];
	[heightField_i	setIntValue:t->r.size.height];
	[patchField_i	setIntValue:t->patchamount];
	r = t->r;
	r.origin.x -= SPACING;
	r.origin.y -= SPACING;
	r.size.width += SPACING*2;
	r.size.height += SPACING*2;
	[texturePalView_i	scrollRectToVisible:r];
	//[texturePalScrView_i setNeedsDisplay:YES];
	return i;
}

- (void)selectTexture:(int)val
{
	texpal_t	*t;
	NSRect		r;
	
	selectedTexture = val;
	if (val >= 0)
	{
		t = [self	getTexture:val];
		[titleField_i	setStringValue:@(t->name)];
		[widthField_i	setIntValue:t->r.size.width];
		[heightField_i	setIntValue:t->r.size.height];
		[patchField_i	setIntValue:t->patchamount];
		r = t->r;
		r.origin.x -= SPACING;
		r.origin.y -= SPACING;
		r.size.width += SPACING*2;
		r.size.height += SPACING*2;
		[texturePalView_i		scrollRectToVisible:r];
		//[texturePalScrView_i	setNeedsDisplay:YES];
	}
}

- (char *)getSelTextureName
{
	return	[self getTexture:selectedTexture]->name;
}

- (void)setSelTexture:(const char *)name
{
	int	i,		max;
	NSRect		r;
	texpal_t	*t;
	
	max = [allTextures	count];
	for (i = 0;i < max; i++)
		if (!strcasecmp(name,((texpal_t *)(t = [allTextures elementAt:i]))->name))
		{
			if (!window_i)
				[self	menuTarget:NULL];
			else
				[window_i	orderFront:NULL];
			[self	selectTexture:i];
			r = t->r;
			r.origin.x -= SPACING;
			r.origin.y -= SPACING;
			r.size.width += SPACING*2;
			r.size.height += SPACING*2;
			[texturePalView_i	scrollRectToVisible:r];
			//[texturePalScrView_i	display];
			break;
		}
}

- (IBAction)searchForTexture:sender
{
	int	i, max, slen,j;
	NSString *string;
	texpal_t	*t;
	
	string = [searchField_i	stringValue];
	slen = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	max = [allTextures	count];
	
	for (i = selectedTexture+1;i < max;i++)
	{
		t = [allTextures	elementAt:i];
		for (j=0;j<strlen(t->name);j++)
			if (!strncasecmp(string.UTF8String,t->name+j,slen))
			{
				[self	setSelTexture:t->name];
				return;
			}
	}
	
	for (i = 0;i <= selectedTexture;i++)
	{
		t = [allTextures	elementAt:i];
		for (j=0;j<strlen(t->name);j++)
			if (!strncasecmp(string.UTF8String,t->name+j,slen))
			{
				[self	setSelTexture:t->name];
				return;
			}
	}
	
	NSBeep();
}

- (int) currentSelection
{
	return selectedTexture;
}

- (int) getNumTextures
{
	return [allTextures	count];
}

- (int) getTextureIndex:(char *)name
{
	NSInteger	i,max;
	texpal_t	*t;
	
	if ((name[0]=='-') || (!name[0] ))
		return -1;
	max = [allTextures	count];
	for (i = 0;i < max;i++)
	{
		t = [allTextures	elementAt:i];
		if (!strcasecmp(name,t->name))
			return (int)i;
	}
	
	return -2;
}

//========================================================
//
//	Search for specific width
//
//========================================================
- (IBAction)searchWidth:sender
{
	int	i, max,width;
	texpal_t	*t;
	
	width = [widthSearch_i	intValue];
	max = [allTextures	count];
	for (i = selectedTexture + 1;i < max;i++)
	{
		t = [allTextures	elementAt:i];
		if (t->r.size.width == width)
		{
			[self	setSelTexture:t->name];
			return;
		}
	}
	
	for (i = 0;i < selectedTexture;i++)
	{
		t = [allTextures	elementAt:i];
		if (t->r.size.width == width)
		{
			[self	setSelTexture:t->name];
			return;
		}
	}
	
	NSBeep();
}

//========================================================
//
//	Search for specific height
//
//========================================================
- (IBAction)searchHeight:sender
{
	int	i, max,height;
	texpal_t	*t;
	
	height = [heightSearch_i	intValue];
	max = [allTextures	count];
	for (i = selectedTexture + 1;i < max;i++)
	{
		t = [allTextures	elementAt:i];
		if (t->r.size.height == height)
		{
			[self	setSelTexture:t->name];
			return;
		}
	}
	
	for (i = 0;i < selectedTexture;i++)
	{
		t = [allTextures	elementAt:i];
		if (t->r.size.height == height)
		{
			[self	setSelTexture:t->name];
			return;
		}
	}
	
	NSBeep();
}

//========================================================
//
//	Show current texture in map by highlighting all lines that use it
//
//========================================================
- (IBAction)showTextureInMap:sender
{
	int		i;
	int		found;
	char	 name[32];
	char	string[64];
	
	strlcpy(name,[searchField_i stringValue].UTF8String, sizeof(name));
	strupr(name);
	found = 0;
	[log_i addLogString:@"Searching for texture in lines...\n"];
	
	for (i = 0;i < numlines;i++)
		if ((!strcasecmp(lines[i].side[0].bottomtexture,name) ||
			!strcasecmp(lines[i].side[0].midtexture,name) ||
			!strcasecmp(lines[i].side[0].toptexture,name) ||
			!strcasecmp(lines[i].side[1].bottomtexture,name) ||
			!strcasecmp(lines[i].side[1].midtexture,name) ||
			!strcasecmp(lines[i].side[1].toptexture,name)) &&
			lines[i].selected != -1 )
		{
			[editworld_i	selectLine:i];
			[editworld_i	selectPoint:lines[i].p1];
			[editworld_i	selectPoint:lines[i].p2];
			sprintf(string,"Showing line #%d\n",i);
			[log_i	msg:string];
			found = 1;
		}

	[editworld_i	redrawWindows];
	if (found)
		NSBeep();
}

//========================================================
//
//	Save currently selected texture out as an LBM !!!
//	and also save out .LS file for graphic
//
//========================================================
- (IBAction)saveTextureLBM:sender
{
	int			cs;
	NSString	*lbmname;
	NSString	*lsname;
	NSString	*waddir;
	FILE		*fp;
	
	cs = [self	currentSelection];
	if (cs < 0)
	{
		NSBeep();
		return;
	}

	waddir = doomproject_i.wadFile.stringByDeletingLastPathComponent;
	
	lbmname = [waddir stringByAppendingPathComponent:[[NSString stringWithFormat:@"%s.LBM", textures[cs].name] lowercaseString]];
	lsname = [waddir stringByAppendingPathComponent:[[NSString stringWithFormat:@"%s.LS", textures[cs].name] lowercaseString]];
	
	fp = fopen (lsname.fileSystemRepresentation,"w+");
	if (fp == NULL)
	{
		printf ("Error creating %s file!\n",lsname.UTF8String);
		return;
	}

	createAndSaveLBM(lbmname.fileSystemRepresentation, cs, fp);
	fclose (fp);
}

//========================================================
//
//	Save ALL textures out as LBMs !!!
//	and also save out .LS file for each graphic
//
//========================================================
- (IBAction)saveAllTexturesAsLBM:sender
{
	[lsPanel_i	makeKeyAndOrderFront:NULL];
}

- (IBAction)doSaveAllTexturesAsLBM:sender
{
	NSString	*lbmname;
	NSString	*lsEnteredName;
	NSString	*waddir;
	int		j;
	FILE	*fp;
	NSString	*lsname;
	char	status[32];
	
	
	lsEnteredName = [lsTextField_i stringValue];
	if (lsEnteredName.length == 0 || lsEnteredName.length>12)
	{
		NSBeep();
		return;
	}
	
	waddir = [[doomproject_i wadFile] stringByDeletingLastPathComponent];
	
	if ([[lsEnteredName pathExtension] caseInsensitiveCompare:@"LS"] != NSOrderedSame) {
		lsEnteredName = [lsEnteredName stringByAppendingPathExtension:@"ls"];
	}
	
	lsname = [waddir stringByAppendingPathComponent:lsEnteredName.lowercaseString];
	
	fp = fopen (lsname.fileSystemRepresentation,"w+");
	if (fp == NULL)
	{
		printf ("Error creating %s file!\n",lsname.UTF8String);
		return;
	}
	
	for (j = 0; j < numtextures; j++)
	{
		lbmname = [waddir stringByAppendingPathComponent:[[NSString stringWithFormat:@"%s.LBM", textures[j].name] lowercaseString]];
		sprintf(status,"Making %s.LBM...",textures[j].name);

		[lsStatus_i	setStringValue:@(status)];
		PSwait();
		createAndSaveLBM(lbmname.fileSystemRepresentation, j, fp);
	}

	fclose (fp);
	
	[lsPanel_i	close];
}


@end

//========================================================
//
//	Create and Save an LBM along with the LS info
//
//	name = what to name the LBM
//	cs   = which texture to create an LBM of
//	fp   = FILE * for .LS script
//
//========================================================
void createAndSaveLBM(const char *name, int cs, FILE *fp)
{
	byte	*texturedata;
	byte	*palette;
	int		tw;
	int		th;
	
	[wadfile_i release]; wadfile_i = nil;
	wadfile_i = [[Wadfile alloc] initWithFilePath:[doomproject_i wadFile]];
	palette = [wadfile_i	loadLumpNamed:"playpal"];
	[ wadfile_i	close ];
	
	tw = textures[cs].width;
	th = textures[cs].height;
	texturedata = malloc(tw * th);
	memset(texturedata,255,tw * th);
	
	//	CREATE THE TEXTURE GRAPHIC
	createVgaTexture(texturedata, cs, tw, th);

	// CREATE THE .LBM
	SaveRawLBM (name, texturedata, tw, th, palette);

	free(texturedata);
	
	// CREATE THE LUMPY SCRIPT
	fprintf(fp,"\x0d\n$load %s.lbm\x0d\n",textures[cs].name);
	fprintf(fp,"%s	VRAW	0	0	%d	%d\x0d\n\x0d\n",
			textures[cs].name,tw,th);
}


//========================================================
//
//	Construct a VGA texture from VGA patches
//
//========================================================
void createVgaTexture(char *dest, int which,int width, int height)
{
	int		i;
	int		patchw;
	int		patchh;
	
	[ wadfile_i	initFromFile: [[doomproject_i wadFile] fileSystemRepresentation] ];
	
	for (i = 0; i < textures[which].patchcount; i++)
	{
		worldpatch_t	*p;
		patch_t			*patch;
		byte			*raw;
		
		//	For each patch in texture:
		//		a. load patch from WAD
		//		b. convert patch to VGA raw
		//		c. blit raw to dest buffer x,y
		
		p = &textures[which].patches[i];
		
		patch = [wadfile_i	loadLumpNamed:p->patchname];
		patchw = patch->width;
		patchh = patch->height;
		raw = malloc(patchw * patchh);
		
		vgaPatchDecompress(patch,raw);
		moveVgaPatch(raw, dest, p->originx, p->originy, patchw, patchh,
			width, height);
		
		free(raw);
		free(patch);
	}

	[ wadfile_i	close ];
}

//========================================================
//
//	Move VGA raw data to x,y in dest buffer
//
//	raw 	= source data
//	dest	= destination buffer
//	x		= dest buffer x
//	y		= dest buffer y
//	width	= raw's width
//	height	= raw's height
//	clipwidth = dest's width
//	clipheight = dest's height
//
//========================================================
void moveVgaPatch(byte *raw, byte *dest, int x, int y,
	int	width, int height,
	int clipwidth, int clipheight)
{
	int		i;
	int		nwidth;
	int		nheight;
	int		xoff;
	int		yoff;
	int		j;
	int		val;
	byte	*src;
	byte	*dst;
	
	nwidth = width;
	if (x + width > clipwidth)
		nwidth = clipwidth - x;
		
	nheight = height;
	if (y + height > clipheight)
		nheight = clipheight - y;
	
	xoff = 0;
	if (x < 0)
	{
		xoff = abs(x);
		x = 0;
	}
	
	yoff = 0;
	if (y < 0)
	{
		yoff = abs(y);
		y = 0;
	}
		
	dst = dest + y*width + x;
	for (i = yoff; i < nheight; i++)
	{
		src = raw + i*width + xoff;
		dst = dest + y*clipwidth + x + (i-yoff)*clipwidth;
		for (j = xoff; j < nwidth; j++)
		{
			val = *src++;
			if (val != 255)
				*dst = val;
			dst++;
		}
	}
}

//========================================================
//
//	Decompress VGA patch data into raw VGA block shape
//
//========================================================
void vgaPatchDecompress(patch_t *patchData,byte *dest_p)
{
	int		count;
	int		topdelta;
	int		i;
	int		index;
	int		width;
	int		height;
	byte	*data;

	//
	// translate the picture
	//
	width = patchData->width;
	height = patchData->height;
	memset(dest_p,255,width * height);
	
	for (i = 0;i < width; i++)
	{
		data = (byte *)patchData + LongSwap(patchData->collumnofs[i]);
		while (1)
		{
			topdelta = *data++;
			if (topdelta == (byte)-1)
				break;
			count = *data++;
			index = topdelta*width+i;	// destination index
			data++;						// skip top double
			while (count--)
			{
				*((unsigned char *)(dest_p + index)) = *data++;
				index += width;
			}
			data++;		// skip bottom double
		}
	}
}
