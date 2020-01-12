// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"TextureEdit.h"
#import	"TexturePalette.h"
#import	"DoomProject.h"
#import	"Wadfile.h"
#import	<ctype.h>
#import	"lbmfunctions.h"

id	textureEdit_i;
id	texturePatches;

@implementation TextureEdit

- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	window_i = NULL;
	textureEdit_i = self;
	currentTexture = -1; 
	oldx = oldy = 0;
	return self;
}

- saveFrame
{
	if (window_i)
#ifdef REDOOMED
		[window_i	saveFrameUsingName:@"TextureEditor"];
#else // Original
		[window_i	saveFrameUsingName:"TextureEditor"];
#endif

	if (createTexture_i)
#ifdef REDOOMED
		[createTexture_i	saveFrameUsingName:@"CTexturePanel"];
#else // Original
		[createTexture_i	saveFrameUsingName:"CTexturePanel"];
#endif

	return self;
}

//
// user wants to activate the Texture Editor. If it hasn't been used yet,
// init everything, otherwise just pull it back up.
//
- menuTarget:sender
{
	if (![doomproject_i loaded])
	{
		NXRunAlertPanel("Oops!",
						"There must be a project loaded before you even\n"
						"THINK about editing textures!",
						"OK",NULL,NULL,NULL);
		return self;
	}
	
	if (!window_i)
	{
		NXSize	s;
		NXRect	dvf;
		NXPoint	startPoint;
		int		ns, i;
		
		[NXApp 
			loadNibSection:	"TextureEdit.nib"
			owner:			self
			withNames:		NO
		];

#ifdef REDOOMED
		// NSTextFields don't send their action message if their window resigns key while
		// they're being edited, and the text changes will be lost if the textfield's
		// content is changed programmatically before the window becomes key again;
		// to avoid losing the user's input, make edited textfields send their action
		// immediately if the panel resigns key
		[window_i rdeSetupTextfieldsToSendActionWhenPanelResignsKey];
#endif
		
		[window_i	setDelegate:self];
		[self		computePatchDocView:&dvf];
		[texturePatchView_i	sizeTo:dvf.size.width :dvf.size.height];

		//
		// start patches at top
		//
		#if 0
		[texturePatchScrollView_i	getContentSize:&s];
		startPoint.x = 0;
		startPoint.y = dvf.size.height - s.height;
		[texturePatchView_i		scrollPoint:&startPoint];
		#endif
		[self	setSelectedPatch:0];

		//
		// start texture editor at top
		//
		[textureView_i		getFrame:&dvf];
		[scrollView_i		getContentSize:&s];
		startPoint.y = dvf.size.height - s.height;

#ifdef REDOOMED
		// Initialize value of startPoint.x
		startPoint.x = 0;

		// Cocoa's scrollPoint: takes a value, not a pointer
		[textureView_i		scrollPoint:startPoint];
#else // Original
		[textureView_i		scrollPoint:&startPoint];
#endif
	
		selectedTexturePatches = [[Storage	alloc]
							initCount:		0
							elementSize:	sizeof(int)
							description:	NULL];
		
#ifdef REDOOMED
		[window_i	setFrameUsingName:@"TextureEditor"];
		[createTexture_i	setFrameUsingName:@"CTexturePanel"];
#else // Original
		[window_i	setFrameUsingName:"TextureEditor"];
		[createTexture_i	setFrameUsingName:"CTexturePanel"];
#endif
		
		[splitView_i	addSubview:topView_i];
		[splitView_i	addSubview:botView_i];
		[splitView_i	setDelegate:self];

		//
		//	Create more radio buttons if more texture sets exist
		//
		ns = [self	numSets ];
		for (i = 0; i < ns; i++)
			[self	createNewSet:NULL ];
	}
	
	[self	newSelection:currentTexture];
	[window_i	makeKeyAndOrderFront:NULL];
	return self;
}

//
//	Delegate method called by NXSplitView (splitView_i)
//
#ifdef REDOOMED
// Cocoa versions

#   define kMinSplitViewCoordinate              150
#   define kMaxSplitViewCoordinateHeightOffset  250

- (CGFloat) splitView: (NSSplitView *) sender
            constrainMinCoordinate: (CGFloat) proposedMin
            ofSubviewAt: (NSInteger) offset
{
    return kMinSplitViewCoordinate;
}

- (CGFloat) splitView: (NSSplitView *) splitView
            constrainMaxCoordinate: (CGFloat) proposedMaximumPosition
            ofSubviewAt: (NSInteger) dividerIndex
{
    return [splitView frame].size.height - kMaxSplitViewCoordinateHeightOffset;
}

#else // Original

- splitView:sender 
	getMinY:(NXCoord *)minY 
	maxY:(NXCoord *)maxY 
	ofSubviewAt:(int)offset
{
	if (*minY < 100)
		*minY = 100;
	if (*maxY > 350)
		*maxY = 350;
	[sender	adjustSubviews];
	return self;
}

#endif // Original

- (int)numSets
{
	int	i, max;
	
	max = 0;
	for (i = 0; i < numtextures; i++)
		if (textures[i].WADindex > max)
			max = textures[i].WADindex;
	return max;
}

#ifndef REDOOMED // Original (Disable for ReDoomEd - unused)
- windowDidMiniaturize:sender
{
	[sender	setMiniwindowIcon:"DoomEd"];
	[sender	setMiniwindowTitle:"TextureEdit"];
	return self;
}
#endif


//=====================================================
//
//	TEXTURE PATCH STUFF
//
//=====================================================

//
// sort the "selected patches" list so pasting looks correct
//
- sortSelectedList
{
	int	i,max,found,*e1,*e2,temp;
	
	max = [selectedTexturePatches	count] - 1;
	do
	{
		found = 0;
		for (i = 0;i < max;i++)
		{
			e1 = [selectedTexturePatches elementAt:i];
			e2 = [selectedTexturePatches elementAt:i+1];
			if (*e2 < *e1)
			{
				temp = *e1;
				*e1 = *e2;
				*e2 = temp;
				found = 1;
			}
		}
	} while(found);
	return self;
}

//
// copy patches
//
- copy:sender
{
	int	i,max;

	if ([copyList	count])
		[copyList	empty];
	
	copyList = [[Storage	alloc]
				initCount:		0
				elementSize:	sizeof(texpatch_t)
				description:	NULL];
	[self	sortSelectedList];
	max = [selectedTexturePatches	count];
	for (i = 0;i < max;i++)
		[copyList		addElement:
			(texpatch_t *)[texturePatches elementAt:
			*(int *)[selectedTexturePatches elementAt:i]]];
	
	[selectedTexturePatches	empty];
	[textureView_i		display];
	return self;
}

//
// paste patches
//
- paste:sender
{
	texpatch_t	p;
	int	i,max = [copyList	count], val, xoff, yoff;
	NXRect	dvr;
	
	if (!max)
	{
		NXBeep();
		return self;
	}
	
	[scrollView_i	getDocVisibleRect:&dvr];
	xoff = dvr.origin.x - ((texpatch_t *)[copyList	elementAt:0])->r.origin.x;
	yoff = dvr.origin.y - ((texpatch_t *)[copyList	elementAt:0])->r.origin.y;
	
	[selectedTexturePatches	empty];
	for (i = 0; i < max; i++)
	{
		p = *(texpatch_t *)[copyList	elementAt:i];
		p.r.origin.x += 10 + xoff;
		p.r.origin.y += 10 + yoff;
		[texturePatches	addElement:&p];
		val = [texturePatches count] - 1;
		[selectedTexturePatches	addElement:&val];
	}
	[textureView_i		display];
	return self;
}

//
// move a patch up in the patch hierarchy
//
- sortUp:sender
{
	int	newpatch;
	texpatch_t	*t, t1, t2;

	if (	([self		getCurrentEditPatch] < 0) ||
		([texturePatches	count] - 1 == [self	getCurrentEditPatch]))
	{
		NXBeep();
		return self;
	}
	
	t = [texturePatches	elementAt:[self	getCurrentEditPatch]];
	if (t->patchLocked)
	{
		NXBeep();
		return self;
	}
	
	newpatch = [self	getCurrentEditPatch];
	do
	{
		newpatch++;
		t = [texturePatches	elementAt:newpatch];
		if (!t)
		{
			NXBeep();
			return self;
		}
	} while (t->patchLocked);

	t2 = *t;
	t = [texturePatches	elementAt:[self	getCurrentEditPatch]];
	t1 = *t;
	[texturePatches	removeElementAt:newpatch];
	[texturePatches	removeElementAt:[self	getCurrentEditPatch]];
	[texturePatches	insertElement:&t2	at:[self getCurrentEditPatch]];
	[texturePatches	insertElement:&t1	at:newpatch];
	[self	changeSelectedTexturePatch:0 to:newpatch];

	[textureView_i		display];
	return self;
}

//
// move a patch down in the patch hierarchy
//
- sortDown:sender
{
	int	newpatch;
	texpatch_t	*t, t1, t2;

	if ([self	getCurrentEditPatch] < 1)
	{
		NXBeep();
		return self;
	}
	
	t = [texturePatches	elementAt:[self	getCurrentEditPatch]];
	if (t->patchLocked)
	{
		NXBeep();
		return self;
	}
	
	newpatch = [self	getCurrentEditPatch];
	do
	{
		newpatch--;
		t = [texturePatches	elementAt:newpatch];
		if (!t)
		{
			NXBeep();
			return self;
		}
	} while (t->patchLocked);

	t2 = *t;
	t = [texturePatches	elementAt:[self	getCurrentEditPatch]];
	t1 = *t;
	[texturePatches	removeElementAt:[self	getCurrentEditPatch]];
	[texturePatches	removeElementAt:newpatch];
	[texturePatches	insertElement:&t1	at:newpatch];
	[texturePatches	insertElement:&t2	at:[self getCurrentEditPatch]];
	[self	changeSelectedTexturePatch:0 to:newpatch];

	[textureView_i		display];
	return self;
}

//===============================================================
//
//	Set patch X manually
//
//===============================================================
- changePatchX:sender
{
	texpatch_t	*tp;
	int			delta;
	
	if (![selectedTexturePatches	count])
		return self;
		
	tp = [texturePatches	elementAt:*(int *)
		[selectedTexturePatches  elementAt:0]];
		
	delta = 2*[texturePatchXField_i	intValue] - tp->r.origin.x;
	tp->r.origin.x += delta;
	tp->patchInfo.originx += delta/2;
	
	[textureView_i		display];
	
	return self;
}

//===============================================================
//
//	Set patch Y manually
//
//===============================================================
- changePatchY:sender
{
	texpatch_t	*tp;
	int			delta;
	
	if (![selectedTexturePatches	count])
		return self;

	tp = [texturePatches	elementAt:*(int *)
		[selectedTexturePatches  elementAt:0]];
		
	delta = 2*[texturePatchYField_i	intValue] - tp->r.origin.y;
	tp->r.origin.y += delta;
	tp->patchInfo.originy -= delta/2;
	
	[textureView_i		display];
	
	return self;
}

//===============================================================
//
//	Set a patch as selected in the Patch Palette
//	AND scroll the Patch Palette to that patch!
//
//===============================================================
- selectPatchAndScroll:(int)patch
{
	NXRect		r;
	apatch_t	*p;
	
	p = [patchImages	elementAt:patch ];
	[self	setSelectedPatch:patch];
	r = p->r;
	r.origin.x -= SPACING;
	r.origin.y -= SPACING;
	r.size.width += SPACING*2;
	r.size.height += SPACING*2;

#ifdef REDOOMED
	// Cocoa's scrollRectToVisible: takes a value, not a pointer
	[texturePatchView_i	scrollRectToVisible:r];
#else // Original
	[texturePatchView_i	scrollRectToVisible:&r];
#endif

	[texturePatchScrollView_i	display];
	return self;
}

//===============================================================
//
//	Search for patch in Patch Palette
//
//===============================================================
- searchForPatch:sender
{
	char		string[9];
	apatch_t	*p;
	int			max;
	int			i;
	int			j;
	int			slen;
	
#ifdef REDOOMED
	// prevent buffer overflows: strcpy() -> macroRDE_SafeCStringCopy()
	macroRDE_SafeCStringCopy(string, RDE_CStringFromNSString([patchSearchField_i stringValue]));
#else // Original	
	strcpy(string,[patchSearchField_i	stringValue]);
#endif

	slen = strlen(string);
	
	max = [patchImages	count];
	if (selectedPatch < 0)
		selectedPatch = 0;
		
	for (i = selectedPatch+1;i < max;i++)
	{
		p = [patchImages	elementAt:i];
		for (j = 0;j < strlen(p->name);j++)
			if (!strncasecmp(string,p->name+j,slen))
			{
				[self	setSelectedPatch:i];
				return self;
			}
	}
	
	for (i = 0;i <= selectedPatch;i++)
	{
		p = [patchImages	elementAt:i];
		for (j = 0;j < strlen(p->name);j++)
			if (!strncasecmp(string,p->name+j,slen))
			{
				[self	setSelectedPatch:i];
				return self;
			}
	}
	
	return self;
}

//
// find in the Patch Palette the single patch selected in the Texture Editor
//
- findPatch:sender
{
	apatch_t	*patch;
	texpatch_t	*tp;
	int		pnum, c, max;
	
	c =[selectedTexturePatches	count];
	if (!c || c > 1)
	{
		NXBeep();
		return self;
	}
	
	tp = [texturePatches	elementAt:*(int *)[selectedTexturePatches  elementAt:0]];
	max = [patchImages	count ];
	for (pnum = 0; pnum < max; pnum++)
	{
		patch = [patchImages	elementAt:pnum ];
		if ( !strcasecmp (patch->name, tp->patchInfo.patchname ) )
			break;
	}
	
	[self	setSelectedPatch:pnum];
	return self;
}

//
// Internal routine. Non-useness
// Find highest #ed patch in selection list and return value & toast in list
//
- (int)findHighestNumberedPatch
{
	int	count = 0, high = 0, *val, pos = 0;
	while((val = [selectedTexturePatches	elementAt:count]) != NULL)
	{
		if (*val > high)
		{
			high = *val;
			pos = count;
		}
		count++;
	}
	[selectedTexturePatches	removeElementAt:pos];
	return high;
}

//
// delete all patches selected in the Texture Editor
//
- deleteCurrentPatch:sender
{
	int	count, i;
	
	count = [selectedTexturePatches	count];
	if (!count)
	{
		NXBeep();
		return self;
	}
	
	for (i = 0; i < count; i++)
		[texturePatches	removeElementAt:[self findHighestNumberedPatch]];
	[selectedTexturePatches	empty];
	
	[textureView_i		display];
	return self;
}

//
// return which patch is selected in edit view
//
- (int)getCurrentEditPatch
{
	int	amount;
	
	amount = [selectedTexturePatches	count];
	if (!amount || amount > 1)
		return -1;
	else
		return *(int *)[selectedTexturePatches	elementAt:0];
}

- (BOOL) selTextureEditPatchExists:(int)val
{
	int	count = 0,*v;
	while((v = [selectedTexturePatches	elementAt:count++]) != NULL)
		if (*v == val)
			return YES;
	return NO;
}

- updateTexPatchInfo
{
	texpatch_t	*t;
	int	c = [selectedTexturePatches	count];

	if (!c || c > 1)
	{
		[texturePatchXField_i	setIntValue:0];
		[texturePatchYField_i	setIntValue:0];
		[lockedPatch_i	setEnabled:NO];

#ifdef REDOOMED
		[texturePatchWidthField_i	setStringValue:@""];
		[texturePatchHeightField_i	setStringValue:@""];
		[texturePatchNameField_i	setStringValue:@""];
#else // Original
		[texturePatchWidthField_i	setStringValue:NULL];
		[texturePatchHeightField_i	setStringValue:NULL];
		[texturePatchNameField_i	setStringValue:NULL];
#endif
	}
	else
	{
		t = [texturePatches	elementAt:*(int *)[selectedTexturePatches elementAt:0]];
		[texturePatchXField_i	setIntValue:t->r.origin.x / 2];
		[texturePatchYField_i	setIntValue:t->r.origin.y / 2];
		[lockedPatch_i	setEnabled:YES];
		[lockedPatch_i	setIntValue:t->patchLocked];
		[texturePatchWidthField_i	setIntValue:t->r.size.width / 2];
		[texturePatchHeightField_i	setIntValue:t->r.size.height / 2];

#ifdef REDOOMED
		[texturePatchNameField_i	setStringValue:
                                            RDE_NSStringFromCString(t->patchInfo.patchname)];
#else // Original
		[texturePatchNameField_i	setStringValue:t->patchInfo.patchname];
#endif
	}		
	return self;
}

- removeSelTextureEditPatch:(int)val
{
	int	count = 0,*v;
	while ((v = [selectedTexturePatches	elementAt:count]) != NULL)
		if (*v == val)
		{
			[selectedTexturePatches	removeElementAt:count ];
			break;
		}
		else
			count++;
	return self;
}

- getSTP
{
	return	selectedTexturePatches;
}

- changeSelectedTexturePatch:(int)which	to:(int)val
{
	*(int *)[selectedTexturePatches	elementAt:which] = val;
	return self;
}

//
// add texture patch # to selected array
//
- addSelectedTexturePatch:(int)val
{
	[selectedTexturePatches	addElement:&val];
	return self;
}

//
// patch lock switch was modified, so change patch flag
//
- doLockToggle
{
	[lockedPatch_i	setIntValue:1 - [lockedPatch_i intValue]];
	[self	togglePatchLock:NULL];
	return self;
}

- togglePatchLock:sender
{
	int	val;
	texpatch_t	*t;
	
	if ([self	getCurrentEditPatch] < 0)
	{
		NXBeep();
		return self;
	}
	val = [lockedPatch_i	intValue];
	t = [texturePatches	elementAt:[self	getCurrentEditPatch]];
	t->patchLocked = val;
	return self;
}

//
// return current patch in edit window
//
- (int)getCurrentPatch
{
	return	selectedPatch;
}

//
// the "outline patches" switch was modified, so redraw edit view
//
- outlineWasSet:sender
{
	[window_i	display];
	return self;
}

//
// return status of outline switch
//
- (int)getOutlineFlag
{
	return [outlinePatches_i		intValue];
}

//
// return * to patch image object
//
- (apatch_t *)getPatch:(int)which
{
	return	[patchImages	elementAt:which];
}

//=====================================================
//
//	TEXTURE STUFF
//
//=====================================================


//
// user changed the width/height/title of the texture. validate & change.
//
- changedWidthOrHeight:sender
{
	worldtexture_t		tex;
	texpatch_t		*p;
	int		count, deltay;
	NXRect	tr, nr;
	
#ifdef REDOOMED
	// Bugfix: return if no current texture, otherwise can crash
	if (currentTexture < 0)
	{
		NXBeep();
		[textureWidthField_i setIntValue: 0];
		[textureHeightField_i setIntValue: 0];
		return self;
	}

	// Bugfix: verify width & height are >= 1 to avoid creating an invalid texture
	if ([textureWidthField_i intValue] < 1)
	{
		[textureWidthField_i setIntValue: MAX(textures[currentTexture].width, 1)];
	}

	if ([textureHeightField_i intValue] < 1)
	{
		[textureHeightField_i setIntValue: MAX(textures[currentTexture].height, 1)];
	}
#endif

	//
	// save texture first!
	//
	[self	finishTexture:nil];

	//
	// was width or height reduced?
	//
	if (	[textureWidthField_i	intValue] < textures[currentTexture].width ||
		[textureHeightField_i	intValue] < textures[currentTexture].height)
	{
		NXSetRect(&tr,0,0,
				[textureWidthField_i  intValue] * 2,[textureHeightField_i  intValue] * 2);
		count = 0;
		deltay = (textures[currentTexture].height - [textureHeightField_i  intValue]) * 2;
		while((p = [texturePatches	elementAt:count++]) != NULL)
		{
			NXSetRect(&nr,p->r.origin.x,p->r.origin.y - deltay,p->r.size.width,p->r.size.height);
			if (NXIntersectsRect(&nr,&tr) == NO)
			{
				NXBeep();
				NXRunAlertPanel("Oops!",
								"Changing the dimensions like that would leave one or more "
								"patches out in limbo!  Sorry, non-workness!",
								"OK",NULL,NULL);
				[textureWidthField_i	setIntValue:textures[currentTexture].width];
				[textureHeightField_i	setIntValue:textures[currentTexture].height];
				return self;
			}
		}
		
	}

	tex = textures[currentTexture];
	tex.width = [textureWidthField_i	intValue];
	tex.height = [textureHeightField_i	intValue];
	[doomproject_i	changeTexture:currentTexture to:&tex];
	[texturePalette_i		storeTexture:currentTexture];
	[self	newSelection:currentTexture];
	return self;
}

//
//	Create a new texture
//
- makeNewTexture:sender
{
	int	textureNum;
	NSModalResponse rcode;
	worldtexture_t		tex;
	id	cell;
	
	if (![doomproject_i loaded])
		return self;
		
	//
	// create a default new texture
	//
	
	rcode = [NXApp	runModalForWindow:createTexture_i];
	[createTexture_i	close];
	if (rcode == NX_RUNABORTED)
		return self;

	tex.width = [createWidth_i	intValue];
	tex.height = [createHeight_i	intValue];
	tex.patchcount = 0;

	memset(tex.name,0,9);

#ifdef REDOOMED
	strncpy(tex.name,RDE_CStringFromNSString([createName_i stringValue]),8);
#else // Original
	strncpy(tex.name,[createName_i	stringValue],8);
#endif

	cell = [setMatrix_i	selectedCell ];
	tex.WADindex = [cell	tag];
	
	//
	// add it to the world and edit it
	//
	textureNum = [doomproject_i	newTexture: &tex];
	[texturePalette_i	storeTexture: textureNum];
	[self	newSelection:textureNum];
	currentTexture = textureNum;
	//
	// load in all the texture patches
	//
	if (texturePatches)
		[texturePatches	free];
	texturePatches = [[	Storage	alloc]
					initCount:		0
					elementSize:	sizeof(texpatch_t)
					description:	NULL];
	[texturePalette_i	selectTexture:currentTexture];
	oldx = oldy = 0;			
	return self;
}

//
// clicked the "create it!" button in the New Texture dialog
//
- createTextureDone:sender
{
	char name[9];
	
	// clip texture name to 8 characters
	bzero(name,9);

#ifdef REDOOMED
	strncpy(name,RDE_CStringFromNSString([createName_i	stringValue]),8);
#else // Original
	strncpy(name,[createName_i	stringValue],8);
#endif

	strupr(name);

#ifdef REDOOMED
	[createName_i	setStringValue:RDE_NSStringFromCString(name)];
#else // Original
	[createName_i	setStringValue:name];
#endif

	if (	[doomproject_i	textureNamed:name] >= -1)
	{
		NXBeep();
		NXRunAlertPanel("Oops!",
						"You already have a texture with the same name!",
						"OK",NULL, NULL, NULL);
		return self;
	}
	
	if (	[createWidth_i	intValue] &&
		[createHeight_i	intValue] &&
#ifdef REDOOMED
		[[createName_i stringValue] length])
#else // Original
		strlen([createName_i	stringValue]))
#endif
		[NXApp	stopModal];
	else
		NXBeep();

	return self;
}

//
// approve the name entered in the dialog
//
- createTextureName:sender
{
	char name[9];
	
	// clip texture name to 8 characters
	bzero(name,9);

#ifdef REDOOMED
	strncpy(name,RDE_CStringFromNSString([createName_i stringValue]),8);
#else // Original
	strncpy(name,[createName_i	stringValue],8);
#endif

	strupr(name);

#ifdef REDOOMED
	[createName_i	setStringValue:RDE_NSStringFromCString(name)];
#else // Original
	[createName_i	setStringValue:name];
#endif

	if (	[doomproject_i	textureNamed:name] >= -1)
	{
		NXBeep();
		NXRunAlertPanel("Oops!",
						"You already have a texture with the same name!",
						"OK",NULL, NULL, NULL);
	}
	return self;
}

- createTextureAbort:sender
{
	[NXApp	abortModal];
	return self;
}

//======================================================
//
//	Allows selection of another texture set when creating new texture
//
//======================================================
- createNewSet:sender
{
	int		nr, nc;
	id		cell;
	char		string[3];
	
	[setMatrix_i	getNumRows:&nr numCols:&nc ];
	if (nr == 5)
	{
		[newSetButton_i	setEnabled:NO ];
		NXBeep ();
		return self;
	}
	
	[setMatrix_i	addRow ];
	nr++;
	cell = [setMatrix_i	cellAt:nr-1 :0 ];
	sprintf (string, "%d",nr );

#ifdef REDOOMED
	[cell		setTitle:RDE_NSStringFromCString(string) ];
#else // Original
	[cell		setTitle:string ];
#endif

	[cell		setTag: nr-1 ];
	[setMatrix_i	sizeToCells ];
	[setMatrix_i	selectCell:cell ];
	[setMatrix_i	display ];
	
	return self;
}

//======================================================
//
//	Done editing texture. add to texture palette
//
//======================================================
- finishTexture:sender
{
	int	count;
	texpatch_t	*t;
	worldtexture_t		tex;
	
#ifdef REDOOMED
	// Bugfix: return if no current texture, otherwise can crash
	if (currentTexture < 0)
	{
		NXBeep();
		return self;
	}
#endif

	//
	// copy texture info into textures array, then
	// add texture to palette
	//
	count = 0;
	tex.patchcount = [texturePatches count];
	tex.width = textures[currentTexture].width;
	tex.height = textures[currentTexture].height;
	tex.WADindex = textures[currentTexture].WADindex;
	
//	cell = [setMatrix_i	selectedCell ];
//	tex.WADindex = [cell	tag ];
	
	strcpy(tex.name,textures[currentTexture].name);
	while ([texturePatches	elementAt:count] != NULL)
	{
		t = [texturePatches elementAt:count];
		tex.patches[count] = t->patchInfo;
		count++;
	}
	[doomproject_i	changeTexture:currentTexture to:&tex];
	[texturePalette_i	storeTexture:currentTexture];
	
	return self;
}

//
// change to a new texture
//
- newSelection:(int)which
{
	texpatch_t	t;
	int	count,i;

	if (which < 0)
		return self;
		
	currentTexture = which;
	if (texturePatches)
		[texturePatches	free];
	
	texturePatches = [[	Storage	alloc]
					initCount:		0
					elementSize:	sizeof(texpatch_t)
					description:	NULL];
	
	//
	// copy textures from textures array to texturePatches
	//
	count = textures[which].patchcount;
	for (i = 0;i < count; i++)
	{
		t.patchLocked = 0;
		t.patchInfo = textures[which].patches[i];
		t.patch = [self	getPatchImage:t.patchInfo.patchname];
		t.r.origin.x = t.patchInfo.originx * 2;
		t.r.origin.y = (textures[which].height * 2) - 
					(t.patch->r.size.height * 2) - 
					(t.patchInfo.originy * 2);
		t.r.size.width = t.patch->r.size.width * 2;
		t.r.size.height = t.patch->r.size.height * 2;
		[texturePatches	addElement:&t];
		if (t.patch->image_x2 == NULL)
			[self	createPatchX2:t.patch];
	}	
	
	[selectedTexturePatches	empty];
	
	[textureView_i		sizeTo:textures[currentTexture].width * 2
					:textures[currentTexture].height * 2];
	[textureView_i		display];
	
	[textureWidthField_i	setIntValue:textures[currentTexture].width];
	[textureHeightField_i	setIntValue:textures[currentTexture].height];

#ifdef REDOOMED
	[textureNameField_i	setStringValue:RDE_NSStringFromCString(textures[currentTexture].name)];
#else // Original
	[textureNameField_i	setStringValue:textures[currentTexture].name];
#endif

	[textureSetField_i		setIntValue:textures[currentTexture].WADindex + 1 ];
	
	return self;
}

//
// return which texture we're working on
//
- (int)getCurrentTexture
{
	return currentTexture;
}

- setOldVars:(int)x :(int)y
{
	oldx = x;
	oldy = y;
	return self;
}

- setWarning:(BOOL)state
{
#ifdef REDOOMED
	if (state == YES)
		[dragWarning_i	setStringValue:@"Selections dragged outside texture!"];
	else
		[dragWarning_i	setStringValue:@" "];
#else // Original
	if (state == YES)
		[dragWarning_i	setStringValue:"Selections dragged outside texture!"];
	else
		[dragWarning_i	setStringValue:" "];
#endif

	return self;
}

//
// user double-clicked on patch in patch palette.
// add that patch to the texture definition.
//
- addPatch:(int)which
{
	int	ct, ox, oy;
	NXRect	dvr;
	texpatch_t	p;
	apatch_t		*pi;
	
	[scrollView_i	getDocVisibleRect:&dvr];
	ct = currentTexture;
	ox = oldx;
	oy = oldy;
	
	if (ct < 0)
	{
		NXBeep();
		return self;
	}
	
	if ([texturePatches	count] == MAXPATCHES)
	{
		NXRunAlertPanel(	"Um!",
						"A maximum of 100 patches is in force!",
						"OK",NULL,NULL);
		return self;
	}
	
	if (dvr.size.width > textures[ct].width*2)
		dvr.size.width = textures[ct].width*2;
	if (dvr.size.height > textures[ct].height*2)
		dvr.size.height = textures[ct].height*2;

	memset(&p,0,sizeof(p));
	p.patchLocked = 0;
	p.patch = [patchImages	elementAt:which];

	if ([centerPatch_i intValue])
	{
		p.patchInfo.originx = dvr.origin.x/2 + dvr.size.width/4;
		p.patchInfo.originy = dvr.origin.y/2 + dvr.size.height/4;
	}
	else
	{
		//
		// add patch to right side of last patch added
		//
		if (ox >= textures[ct].width)
		{
			NXBeep();
			[centerPatch_i	setIntValue:1];
			p.patchInfo.originx = dvr.origin.x/2 + dvr.size.width/4;
			p.patchInfo.originy = dvr.origin.y/2 + dvr.size.height/4;
		}
		else
		{
			p.patchInfo.originx = ox;
			p.patchInfo.originy = oy;
		}
	}
	ox += p.patch->r.size.width;
	oldx = ox;
	
	memset(p.patchInfo.patchname,0,9);
	pi = [patchImages	elementAt:which ];
	strcpy ( p.patchInfo.patchname, pi->name );

	p.patchInfo.stepdir = 1;
	p.patchInfo.colormap = 0;

	p.r.origin.x = p.patchInfo.originx * 2;
	p.r.origin.y = (textures[ct].height * 2) - 
				(p.patch->r.size.height * 2) - 
				(p.patchInfo.originy * 2);
	p.r.size.width = p.patch->r.size.width * 2;
	p.r.size.height = p.patch->r.size.height * 2;
	
	[texturePatches	addElement:&p];
	//
	// Create x2-sized patch if it doesn't exist yet
	//
	if (p.patch->image_x2 == NULL)
		[self	createPatchX2:p.patch];
	
	//
	// scroll a little more to the right...
	//
	p.r.origin.x += p.r.size.width * 1.5;

#ifdef REDOOMED
	// Cocoa's scrollRectToVisible: takes a value, not a pointer
	[textureView_i		scrollRectToVisible:p.r];
#else // Original
	[textureView_i		scrollRectToVisible:&p.r];
#endif

	[textureView_i		display];
	return self;
}

- fillWithPatch:sender
{
	return self;
}

- sizeChanged:sender
{
	return self;
}

//=====================================================
//
//	PATCH PALETTE STUFF
//
//=====================================================

- (apatch_t *)getPatchImage:(char *)name
{
	int		i, max;
	apatch_t	*p;

	max = [patchImages	count ];
	for (i = 0; i < max; i++)
	{
		p = [patchImages	elementAt:i ];
		if ( !strcasecmp (name, p->name ) )
			return p;
	}
	return NULL;
}

//
// set patch selected in Patch Palette
//
- setSelectedPatch:(int)which
{
	apatch_t	*t;
	NXRect		r;
	
	selectedPatch = which;
	t = [patchImages	elementAt:which];
	[patchWidthField_i		setIntValue:t->r.size.width];
	[patchHeightField_i	setIntValue:t->r.size.height];

#ifdef REDOOMED
	[patchNameField_i		setStringValue: RDE_NSStringFromCString(t->name) ];
#else // Original
	[patchNameField_i		setStringValue: t->name ];
#endif
	
	r = t->r;
	r.origin.x -= SPACING;
	r.origin.y -= SPACING;
	r.size.width += SPACING*2;
	r.size.height += SPACING*2;

#ifdef REDOOMED
	// Cocoa's scrollRectToVisible: takes a value, not a pointer
	[texturePatchView_i			scrollRectToVisible:r];
#else // Original
	[texturePatchView_i			scrollRectToVisible:&r];
#endif

	[texturePatchScrollView_i	display];
	return self;
}

//==========================================================
//
//	Get rid of all patches and their images
//
//==========================================================
- dumpAllPatches
{
	int			i, max;
	apatch_t		*p;
	id			panel;
	
	panel = NXGetAlertPanel("Wait...","Dumping texture patches.",
		NULL,NULL,NULL);
	[panel	orderFront:NULL];
	NXPing();
	
	max = [patchImages	count];
	for (i = 0; i < max; i++)
	{
		p = [patchImages	elementAt: i ];
		[ p->image	free ];
		if (p->image_x2 )
			[p->image_x2  free ];
	}
	
	[ patchImages	empty ];
	if (window_i)
	{
		[ window_i		free ];
		window_i = NULL;
	}
	
	[panel	orderOut:NULL];
	NXFreeAlertPanel(panel);
	return self;
}

//==========================================================
//
//	Load in all the patches and init storage array
//
//==========================================================
- initPatches
{
	int		patchStart, patchEnd, i;
	patch_t	*patch;
	byte 	*palLBM;
	unsigned short	shortpal[256];
	apatch_t	p;
	NXSize	s;
	char	string[80];
	
	int		windex;
	char	start[10], end[10];
	
	palLBM = [wadfile_i	loadLumpNamed:"playpal"];
	if (palLBM == NULL)
		IO_Error ("Need to have 'playpal' palette in .WAD file!");
	LBMpaletteTo16 (palLBM, shortpal);
	patchImages = [	[Storage	alloc]
					initCount:		0
					elementSize:	sizeof(apatch_t)
					description:	NULL];
		
	windex = 0;
	do
	{
		sprintf(string,"Loading patch set #%d for Texture Editor.",windex+1);
		[doomproject_i	initThermo:"One moment..." message:string];
		//
		// get inclusive lump #'s for patches
		//
#ifdef REDOOMED
		// prevent buffer overflows: *sprintf() -> *snprintf() in cases where input strings
		// might be too long for the destination buffer
		snprintf (start, sizeof(start), "p%d_start", windex+1 );
		snprintf (end,sizeof(end),"p%d_end", windex+1 );
#else // Original
		sprintf (start, "p%d_start", windex+1 );
		sprintf (end,"p%d_end", windex+1 );
#endif

		patchStart = [wadfile_i	lumpNamed:start] + 1;
		patchEnd = [wadfile_i	lumpNamed:end];
	
		if (patchStart == -1 || patchEnd == -1)
		{
			if (!windex)
				NXRunAlertPanel(	"OOPS!",
					"There are NO PATCHES in the current .WAD file!",
					"Abort Patch Palette",NULL,NULL,NULL);
			
			windex = -1;
			continue;
		}
		
		NXSetRect(&p.r,0,0,0,0);
		for (i = patchStart; i < patchEnd; i++)
		{
			[doomproject_i	updateThermo:i-patchStart max:patchEnd-patchStart];
			//
			// load vertically compressed patch and convert to an NXImage
			//
			patch = [wadfile_i	loadLump:i];
			memset(&p,0,sizeof(p));
			strcpy(p.name,[wadfile_i  lumpname:i]);
			p.name[8] = 0;
			p.image = patchToImage(patch,shortpal,&s,p.name);
			p.image_x2 = NULL;
			p.size = s;
			p.r.size = s;
			p.WADindex = windex;
			[patchImages	addElement:&p];
			free(patch);
		}
		
		windex++;
	} while (windex >= 0);	

	free(palLBM);
	[doomproject_i	closeThermo];
	return self;
}

//
// make a copy that's 2 times the size
//
- createPatchX2:(apatch_t *)p
{
	NXSize	theSize;
	
	p->image_x2 = [p->image	copyFromZone:NXDefaultMallocZone()];
	theSize = p->size;
	theSize.width *= 2;
	theSize.height *= 2;
	[p->image_x2	setScalable:YES];

#ifdef REDOOMED
	// Cocoa's setSize: takes a value, not a pointer
	[p->image_x2	setSize:theSize];
#else // Original
	[p->image_x2	setSize:&theSize];
#endif

	return self;
}		

//
//	Return # of patches
//
- (int)getNumPatches
{
	return [patchImages	count];
}

//
//	Return index of patch from name
//
- (int)findPatchIndex:(char *)name
{
	int		i, max;
	apatch_t	*p;
	
	max = [patchImages	count];
	for (i = 0;i < max; i++)
	{
		p = [patchImages	elementAt:i];
		if (!strcasecmp(p->name,name))
			return i;
	}
	
	return -1;
}

//
//	Return name of patch from index
//
- (char *)getPatchName:(int)which;
{
	apatch_t	*p;
	
	if (which > [patchImages count])
		return NULL;
	p = [patchImages	elementAt:which];
	return p->name;
}

//
//	Locate patch use in textures
//
- locatePatchInTextures:sender
{
	int	i, j, max, cs;
	char *pname;
	
	if (selectedPatch < 0)
		return self;
		
	pname = [self	getPatchName:selectedPatch];
	
	cs = [texturePalette_i	currentSelection];
	max = [texturePalette_i	getNumTextures];
	for (i = cs+1;i < max; i++)
		for (j = 0; j < textures[i].patchcount; j++)
			if (!strcasecmp(textures[i].patches[j].patchname,pname))
			{
				[texturePalette_i	selectTexture:i];
				[texturePalette_i	setSelTexture:[texturePalette_i getSelTextureName]];
				return self;
			}

	for (i = 0;i <= cs; i++)
		for (j = 0; j < textures[i].patchcount; j++)
			if (!strcasecmp(textures[i].patches[j].patchname,pname))
			{
				[texturePalette_i	selectTexture:i];
				[texturePalette_i	setSelTexture:[texturePalette_i getSelTextureName]];
				return self;
			}
			
	NXBeep ();
	return self;
}

//
// user resized the Texture Edit window.
// change the size of the patch palette.
//
#ifdef REDOOMED
// Cocoa version
- (void) windowDidResize: (NSNotification *) notification
#else // Original
- windowDidResize:sender
#endif
{
	NXRect	r;
	
	[self		computePatchDocView:&r];
	[texturePatchView_i	sizeTo:r.size.width :r.size.height];
	[window_i	display];

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

//
// compute the size of the docView and set the origin of all the patches
// within the docView.
//
- computePatchDocView: (NXRect *)theframe
{
	NXRect	curWindowRect;
	int		x, y, patchnum, maxheight;
	apatch_t	*patch;
	int		maxwindex;
	char		string[32];
	
	[texturePatchScrollView_i		getDocVisibleRect:&curWindowRect];
	x = y =  SPACING;
	maxheight = patchnum = maxwindex = 0;
	while ((patch = [patchImages	elementAt:patchnum++]) != NULL)
	{
		//
		//	Add some space if a new Patch Set is detected
		//
		if (patch->WADindex > maxwindex )
		{
			maxwindex = patch->WADindex;
			x = SPACING;
			y += 80 + maxheight;
		}
	
		if (x + patch->r.size.width > curWindowRect.size.width && x != SPACING)
		{
			x = SPACING;
			y += maxheight + SPACING;
			maxheight = 0;
		}
		
		if (patch->r.size.height > maxheight)
			maxheight = patch->r.size.height;

		if (x + patch->r.size.width > curWindowRect.size.width && x == SPACING)
		{
			y += maxheight + SPACING;
			maxheight = 0;
		}			
		else
			x += patch->r.size.width + SPACING;
	}
	y += maxheight + SPACING;
	NXSetRect(theframe,0,0,curWindowRect.size.width + SPACING,y);
	
	//
	// now go through all the patches and reassign the coords so they
	// stack from top to bottom...
	//
	[texturePatchView_i	dumpDividers];
	maxheight = patchnum = maxwindex = 0;
	x = theframe->origin.x + SPACING;
	y = theframe->origin.y + theframe->size.height - SPACING;
	while ((patch = [patchImages	elementAt:patchnum++]) != NULL)
	{
		//
		//	If a new Patch Set is detected, insert a divider
		//
		if (patch->WADindex > maxwindex )
		{
			maxwindex = patch->WADindex;
			x = SPACING;
			y -= 40 + maxheight;
			sprintf ( string, "Patch Set #%d", maxwindex+1 );
			[texturePatchView_i	addDividerX:x
						Y: y
						String: string ];
			y -= 40;
		}
		
		if (x + patch->r.size.width > curWindowRect.size.width && x != SPACING)
		{
			x = SPACING;
			y -= maxheight + SPACING;
			maxheight = 0;
		}
		
		patch->r.origin.x = x;
		patch->r.origin.y = y - patch->r.size.height;

		if (patch->r.size.height > maxheight)
			maxheight = patch->r.size.height;

		if (x + patch->r.size.width > curWindowRect.size.width && x == SPACING)
		{
			y -= maxheight + SPACING;
			maxheight = 0;
		}			
		else
			x += patch->r.size.width + SPACING;
	}	

	return self;
}


@end

//---------------------------------------------------------------
//
// C ROUTINES
//
//---------------------------------------------------------------



//
// convert a compressed patch to an NXImage with an alpha channel
//
id	patchToImage(patch_t *patchData, unsigned short *shortpal,NXSize *size,char *name)
{
	byte			*dest_p;
	NXImageRep *image_i;
	id			fastImage_i;
	int			width,height,count,topdelta;
	byte const	*data;
	int			i,index;

	width = ShortSwap(patchData->width);
	height = ShortSwap(patchData->height);
	size->width = width;
	size->height = height;
	
	if (!width || !height)
	{
		printf("Can't create NXBitmapImage of %s!  "
			"Width or height = 0.\n",name);
		return NULL;
	}
	//
	// make an NXimage to hold the data
	//
	image_i = [[NXBitmapImageRep alloc]
		initData:			NULL 
		pixelsWide:		width 
		pixelsHigh:		height
		bitsPerSample:	4
		samplesPerPixel:	4 
		hasAlpha:		YES
		isPlanar:			NO 
		colorSpace:		NX_RGBColorSpace 
		bytesPerRow:		width*2
		bitsPerPixel: 		16
	];

#ifdef REDOOMED
	// prevent memory leaks
	[image_i autorelease];
#endif

	if (!image_i)
		return nil;
				
	//
	// translate the picture
	//
	dest_p = [(NXBitmapImageRep *)image_i data];
	memset(dest_p,0,width * height * 2);
	
	for (i = 0;i < width; i++)
	{
		data = (byte *)patchData + LongSwap(patchData->collumnofs[i]);
		while (1)
		{
			topdelta = *data++;
			if (topdelta == (byte)-1)
				break;
			count = *data++;
			index = (topdelta*width+i)*2;
			data++;		// skip top double
			while (count--)
			{
				*((unsigned short *)(dest_p + index)) = shortpal[*data++];
				index += width * 2;
			}
			data++;		// skip bottom double
		}
	}

	fastImage_i = [[NXImage	alloc]
							init];
	[fastImage_i	useRepresentation:(NXImageRep *)image_i];	
	return fastImage_i;
}

char *strupr(char *string)
{
	char *s = string;

#ifdef REDOOMED
	// Bugfix: separated increment statement because it was causing a bug where the string
	// would lose its first char
	while (*string)
	{
		*string = toupper(*string);
		string++;
	}
#else // Original
	while (*string)
		*string++ = toupper(*string);
#endif

	return s;
}

char *strlwr(char *string)
{
	char *s = string;

#ifdef REDOOMED
	// Bugfix: separated increment statement because it was causing a bug where the string
	// would lose its first char
	while (*string)
	{
		*string = tolower(*string);
		string++;
	}
#else // Original
	while (*string)
		*string++ = tolower(*string);
#endif

	return s;
}

