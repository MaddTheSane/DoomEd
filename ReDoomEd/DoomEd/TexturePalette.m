// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"DoomProject.h"
#import	"TextureEdit.h"
#import	"TexturePalette.h"
#import	"TexturePalView.h"
#import	"lbmfunctions.h"
#import	"Wadfile.h"
#import	"TextLog.h"

TexturePalette	*texturePalette_i;

@implementation TexturePalette

- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	window_i = NULL;
	texturePalette_i = self;
	selectedTexture = -1;

	allTextures = [[	Storage	alloc]
				initCount:		0
				elementSize:	sizeof(texpal_t)
				description:	NULL];
	
	return self;
}

- (void)saveFrame
{
	if (window_i)
#ifdef REDOOMED
		[window_i	saveFrameUsingName:@"TexturePalette"];
#else // Original
		[window_i	saveFrameUsingName:"TexturePalette"];
#endif
}

- (void)initTextures
{
	[self	createAllTextureImages];
	[self	finishInit];
}

- (void)finishInit
{
		NXPoint	p;
		NXRect	dvr;
	
		[self	computePalViewSize];
		//
		// start textures at top
		//
		dvr = texturePalView_i.frame;
		p.x = 0;
		p.y = dvr.size.height;

#ifdef REDOOMED
		// Cocoa's scrollPoint: takes a value, not a pointer
		[texturePalView_i		scrollPoint:p];
#else // Original
		[texturePalView_i		scrollPoint:&p];
#endif
}

- (void)setupPalette
{
		[self	finishInit];
		if ([allTextures	count])
			[self	selectTexture:0];

#ifdef REDOOMED
		[window_i	setFrameUsingName:@"TexturePalette"];
#else // Original
		[window_i	setFrameUsingName:"TexturePalette"];
#endif
}

- (IBAction)menuTarget:sender
{
	if (![doomproject_i loaded])
	{
		NSRunAlertPanel(@"Oops!",
						@"There must be a project loaded before you even\n"
						"THINK about choosing textures!",
						@"OK",NULL,NULL,NULL);
		return;
	}
		
	if (!window_i)
	{
		[NXApp 
			loadNibSection:	"TexturePalette.nib"
			owner:			self
			withNames:		NO
		];

		[self setupPalette];
		[window_i	setDelegate:self];
	}

	[window_i	makeKeyAndOrderFront:NULL];
}

#ifndef REDOOMED // Original (Disable for ReDoomEd - unused)
- windowDidMiniaturize:sender
{
	[sender	setMiniwindowIcon:"DoomEd"];
	[sender	setMiniwindowTitle:"TxPalette"];
	return self;
}
#endif


//
// create all the texture images for the palette
// NOTE: allTextures must have been created
//
- (void)createAllTextureImages
{
	int		j;
	texpal_t	t;

#ifdef REDOOMED
	// prevent memory leaks: free texture images pointed to by elements of allTextures
	NSInteger allTexturesCount = [allTextures count];

	for (j=0; j<allTexturesCount; j++)
	{
		[((texpal_t *) [allTextures elementAt: j])->image release];
	}
#endif
	
	[allTextures	empty];
	
	for (j = 0; j < numtextures; j++)
	{
		t = [self	createTextureImage:j];
		[allTextures	addElement:&t];
	}
}

///
/// create a texture image from all its patches for the palette
/// NOTE: allTextures must have been created
///
- (texpal_t) createTextureImage:(int)which
{
	int	i;
	texpal_t	t;
	NXSize	s;

	s.width = textures[which].width;
	s.height = textures[which].height;
	t.r = NSZeroRect;
	t.r.size = s;
	t.WADindex = textures[which].WADindex;
	strcpy(t.name,textures[which].name);
	t.patchamount = textures[which].patchcount;
	t.image = [[NSImage alloc]
			   initWithSize:s];
	[t.image	 useCacheWithDepth:NX_TwelveBitRGBDepth];
	[t.image	lockFocusOn:[t.image lastRepresentation]];
	
	NXSetColor(NXConvertRGBAToColor(1,0,0,1));
	NXRectFill(&t.r);

	for (i = 0; i < textures[which].patchcount; i++)
	{
		texpatch_t	p;
		
		p.patchInfo = textures[which].patches[i];
		p.patch = [textureEdit_i	getPatchImage:p.patchInfo.patchname];
		if (!p.patch)
		{
			NSRunAlertPanel(@"Shit!",
				@"While building texture #%d, I couldn't find "
				"the '%s' patch!",@"OK",NULL,NULL,i,p.patchInfo.patchname);
			[NXApp	terminate:NULL];
		}
		p.r.origin.x = p.patchInfo.originx;
		p.r.origin.y = (textures[which].height) - 
					(p.patch->r.size.height) - 
					(p.patchInfo.originy);
		p.r.size.width = p.patch->r.size.width;
		p.r.size.height = p.patch->r.size.height;
		[p.patch->image drawAtPoint:p.r.origin fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1];
	}
	[t.image	unlockFocus];
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
		[t->image	release];
	}
	
	tex = [self	createTextureImage:which];
	[allTextures	replaceElementAt:which with:&tex];

	[self	computePalViewSize];
	[self	selectTexture:which];
	[doomproject_i	setProjectDirty:TRUE];
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
	NSInteger	count,maxwidth,x,y;
	NXSize	s,imagesize;
	int		maxwindex, i, j;
	char		string[32];
	
	if (newTextures == nil )
		newTextures = [[Storage alloc ]
						initCount: 	[allTextures  count]
						elementSize:	sizeof (texpal_t)
						description:	NULL ];
	else
		[newTextures	empty];
	
	maxwidth = 0;
	x = y = SPACING;
	count = [allTextures count] - 1;
	
	//
	//	See how many texture sets we have
	//
	maxwindex = 0;
	for (i = 0; i <= count; i++) {
		t = [allTextures	elementAt:i ];
		if (t->WADindex > maxwindex)
			maxwindex = t->WADindex;
	}
	
	//
	//	Build newTextures to hold texture sets in order
	//	from allTextures
	//
	for (i = 0; i <= maxwindex; i++) {
		for (j = 0; j <= count; j++) {
			t = [allTextures	elementAt:j ];
			if (t->WADindex == i) {
				t->oldIndex = j;
				[newTextures	addElement: t ];
			}
		}
	}

	//
	//	Compute Texture Palette size
	//
	[texturePalView_i	dumpDividers ];
	while (count >= 0) {
		t = [newTextures	elementAt:count];

		if (t->WADindex < maxwindex) {
			maxwindex = t->WADindex;
			sprintf (string, "Texture Set #%d", maxwindex+2 );
			y += SPACING;
			[texturePalView_i addDividerX: x
										y: y
								   string: @(string)];
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

- (int)selectTextureNamed:(char *)name
{
	texpal_t *t;
	int		i;
	int		max;
	NXRect	r;
	
	max = [allTextures count];
	for (i = 0; i < max; i++)
	{
		t = [allTextures	elementAt:i ];
		if ( !strcasecmp (name, t->name ) )
			break;
	}
	
	selectedTexture = i;
	t = [self	getTexture:i];

#ifdef REDOOMED
	[titleField_i	setStringValue:RDE_NSStringFromCString(t->name)];
#else // Original
	[titleField_i	setStringValue:t->name];
#endif

	[widthField_i	setIntValue:t->r.size.width];
	[heightField_i	setIntValue:t->r.size.height];
	[patchField_i	setIntValue:t->patchamount];
	r = t->r;
	r.origin.x -= SPACING;
	r.origin.y -= SPACING;
	r.size.width += SPACING*2;
	r.size.height += SPACING*2;

#ifdef REDOOMED
	// Cocoa's scrollRectToVisible: takes a value, not a pointer
	[texturePalView_i	scrollRectToVisible:r];
#else // Original
	[texturePalView_i	scrollRectToVisible:&r];
#endif

	[texturePalScrView_i setNeedsDisplay:YES];
	return i;
}

- (void)selectTexture:(int)val
{
	texpal_t	*t;
	NXRect		r;
	
	selectedTexture = val;
	if (val >= 0)
	{
		t = [self	getTexture:val];

#ifdef REDOOMED
		[titleField_i	setStringValue:RDE_NSStringFromCString(t->name)];
#else // Original
		[titleField_i	setStringValue:t->name];
#endif

		[widthField_i	setIntValue:t->r.size.width];
		[heightField_i	setIntValue:t->r.size.height];
		[patchField_i	setIntValue:t->patchamount];
		r = t->r;
		r.origin.x -= SPACING;
		r.origin.y -= SPACING;
		r.size.width += SPACING*2;
		r.size.height += SPACING*2;

#ifdef REDOOMED
		// Cocoa's scrollRectToVisible: takes a value, not a pointer
		[texturePalView_i		scrollRectToVisible:r];
#else // Original
		[texturePalView_i		scrollRectToVisible:&r];
#endif

		[texturePalScrView_i setNeedsDisplay:YES];
	}
}

- (const char *)getSelTextureName
{
	return	[self getTexture:selectedTexture]->name;
}

- (void)setSelTexture:(const char *)name
{
	NSInteger	i, max;
	NXRect	r;
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

#ifdef REDOOMED
			// Cocoa's scrollRectToVisible: takes a value, not a pointer
			[texturePalView_i	scrollRectToVisible:r];
#else // Original
			[texturePalView_i	scrollRectToVisible:&r];
#endif

			[texturePalScrView_i setNeedsDisplay:YES];
			break;
		}
}

- (IBAction)searchForTexture:sender
{
	NSInteger	i, max, slen,j;
	const char *string;
	texpal_t	*t;
	
#ifdef REDOOMED
	string = RDE_CStringFromNSString([searchField_i stringValue]);
#else // Original
	string = [searchField_i	stringValue];
#endif

	slen = strlen(string);
	max = [allTextures	count];
	
	for (i = selectedTexture+1;i < max;i++)
	{
		t = [allTextures	elementAt:i];
		for (j=0;j<strlen(t->name);j++)
			if (!strncasecmp(string,t->name+j,slen))
			{
				[self	setSelTexture:t->name];
				return;
			}
	}
	
	for (i = 0;i <= selectedTexture;i++)
	{
		t = [allTextures	elementAt:i];
		for (j=0;j<strlen(t->name);j++)
			if (!strncasecmp(string,t->name+j,slen))
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

- (NSInteger) countOfTextures
{
	return [allTextures	count];
}

- (NSInteger) getTextureIndex:(const char *)name
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
			return i;
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
	NSInteger	i, max,height;
	texpal_t	*t;
	
	height = [heightSearch_i	integerValue];
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

/// Show current texture in map by highlighting all lines that use it
- (IBAction)showTextureInMap:sender
{
	int		i;
	BOOL	found = NO;
	char	name[32];
	
#ifdef REDOOMED
	// prevent buffer overflows: strcpy() -> macroRDE_SafeCStringCopy()
	macroRDE_SafeCStringCopy(name, RDE_CStringFromNSString([searchField_i stringValue]));
#else // Original	
	strcpy(name,[searchField_i	stringValue]);
#endif

	strupr(name);
	[log_i addMessage:@"Searching for texture in lines...\n"];
	
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
			[log_i addFormattedMessage:@"Showing line #%d\n", i];
			found = YES;
		}

	[editworld_i	redrawWindows];
	if (found)
		NSBeep();
	return;
}

/// Save currently selected texture out as an LBM !!!
/// and also save out .LS file for graphic
- (IBAction)saveTextureLBM:sender
{
	int		cs;
	char	lbmname[1024];
	char	lsname[1024];
	char	waddir[1024];
	size_t	i;
	FILE	*fp;
	
	cs = [self	currentSelection];
	if (cs < 0)
	{
		NSBeep();
		return;
	}

	strcpy(waddir,[doomproject_i wadfile].fileSystemRepresentation);
	for (i = strlen(waddir);i > 0;i--)
		if (waddir[i] == '/')
		{
			waddir[i] = 0;
			break;
		}
		
	sprintf(lbmname,"%s/%s.LBM",waddir,textures[cs].name);
	sprintf(lsname,"%s/%s.LS",waddir,textures[cs].name);
	
#ifdef REDOOMED
	// Bugfix: only convert last path component to lowercase
	strlwr(strrchr(lsname,'/'));
#else // Original
	strlwr(lsname);
#endif

	fp = fopen (lsname,"w+");
	if (fp == NULL)
	{
		printf ("Error creating %s file!\n",lsname);
		return;
	}

#ifdef REDOOMED
	// Bugfix: only convert last path component to lowercase
	strlwr(strrchr(lbmname,'/'));
#else // Original
	strlwr(lbmname);
#endif

	createAndSaveLBM(lbmname, cs, fp);	
	fclose (fp);
}

/// Save ALL textures out as LBMs !!!
/// and also save out .LS file for each graphic
- (IBAction)saveAllTexturesAsLBM:sender
{
	[lsPanel_i	makeKeyAndOrderFront:NULL];
}

- (IBAction)doSaveAllTexturesAsLBM:sender
{
	char	lbmname[1024];
	char	lsEnteredName[24];
	char	waddir[1024];
	int		i;
	int		j;
	FILE	*fp;
	char	lsname[1024];
	char	status[32];
	
	
#ifdef REDOOMED
	// prevent buffer overflows: strcpy() -> macroRDE_SafeCStringCopy()
	macroRDE_SafeCStringCopy(lsEnteredName,
	                            RDE_CStringFromNSString([lsTextField_i stringValue]));
#else // Original	
	strcpy(lsEnteredName,[lsTextField_i	stringValue]);
#endif

	if ((!lsEnteredName[0]) || strlen(lsEnteredName)>12)
	{
		NSBeep();
		return;
	}
	
	strcpy(waddir,[doomproject_i wadfile].fileSystemRepresentation);
	for (i = strlen(waddir);i > 0;i--)
		if (waddir[i] == '/')
		{
			waddir[i] = 0;
			break;
		}
	
	if (strcmp(strupr(lsEnteredName + strlen(lsEnteredName)-3),".LS"))
		strcat(lsEnteredName,".LS");
	
	sprintf(lsname,"%s/%s",waddir,lsEnteredName);

#ifdef REDOOMED
	// Bugfix: only convert last path component to lowercase
	strlwr(strrchr(lsname,'/'));
#else // Original
	strlwr(lsname);	
#endif
	
	fp = fopen (lsname,"w+");
	if (fp == NULL)
	{
		printf ("Error creating %s file!\n",lsname);
		return;
	}
	
	for (j = 0; j < numtextures; j++)
	{
		sprintf(lbmname,"%s/%s.LBM",waddir,textures[j].name);
		sprintf(status,"Making %s.LBM...",textures[j].name);
		
#ifdef REDOOMED
		[lsStatus_i	setStringValue:RDE_NSStringFromCString(status)];
#else // Original		
		[lsStatus_i	setStringValue:status];
#endif

		NXPing();

#ifdef REDOOMED
		// Bugfix: only convert last path component to lowercase
		strlwr(strrchr(lbmname,'/'));
#else // Original
		strlwr(lbmname);
#endif

		createAndSaveLBM(lbmname, j, fp);
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
void createAndSaveLBM(char *name, int cs, FILE *fp)
{
	byte	*texturedata;
	byte	*palette;
	int		tw;
	int		th;
	
	[ wadfile_i	initFromFile: [doomproject_i wadfile].fileSystemRepresentation ];
	palette = [wadfile_i	loadLumpNamed:"playpal"];
	[ wadfile_i	close ];
	
	tw = textures[cs].width;
	th = textures[cs].height;
	texturedata = malloc(tw * th);
	memset(texturedata,255,tw * th);
	
	//	CREATE THE TEXTURE GRAPHIC
	createVgaTexture((char*)texturedata, cs, tw, th);

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
	
	[ wadfile_i	initFromFile: [doomproject_i wadfile].fileSystemRepresentation ];
	
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

#ifdef REDOOMED
		// Bugfix: byte order
		patchw = ShortSwap(patch->width);
		patchh = ShortSwap(patch->height);
#else // Original
		patchw = patch->width;
		patchh = patch->height;
#endif

		raw = malloc(patchw * patchh);
		
		vgaPatchDecompress(patch,raw);
		moveVgaPatch(raw, (byte*)dest, p->originx, p->originy, patchw, patchh,
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
#ifdef REDOOMED
	// Bugfix: byte order
	width = ShortSwap(patchData->width);
	height = ShortSwap(patchData->height);
#else // Original
	width = patchData->width;
	height = patchData->height;
#endif

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
