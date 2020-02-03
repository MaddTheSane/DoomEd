// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"ThingPanel.h"
#import	"ThingStripper.h"

@implementation ThingStripper
//=====================================================================
//
//	Thing Stripper
//
//=====================================================================

//===================================================================
//
//	Load the .nib (if needed) and display the panel
//
//===================================================================
- (IBAction)displayPanel:sender
{
	if (!thingStripPanel_i)
	{
		[NXApp 
			loadNibSection:	"ThingStripper.nib"
			owner:			self
			withNames:		NO
		];
		[thingStripPanel_i	setFrameUsingName:THINGSTRIPNAME];
		[thingStripPanel_i	setDelegate:self];

		thingList_i = [[Storage	alloc]
				initCount:		0
				elementSize:	sizeof(thingstrip_t)
				description:	NULL];
	}
	[thingBrowser_i	reloadColumn:0];
	[thingStripPanel_i	makeKeyAndOrderFront:NULL];
}

#ifndef REDOOMED // Original (Disable for ReDoomEd - unused)
- windowDidMiniaturize:sender
{
	[sender	setMiniwindowIcon:"DoomEd"];
	[sender	setMiniwindowTitle:"ThingStrip"];
	return self;
}
#endif

//
//	Empty list if window gets closed!
//
#ifdef REDOOMED
// Cocoa version
- (void) windowWillClose: (NSNotification *) notification
#else // Original
- windowWillClose:sender
#endif
{
	[thingStripPanel_i	saveFrameUsingName:THINGSTRIPNAME];
	[thingList_i	empty];

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

//===================================================================
//
//	Do actual Thing stripping from all maps
//
//===================================================================
- (IBAction)doStrippingOneMap:sender
{
	int		k,j;
	NSInteger		listMax;
	thingstrip_t	*ts;
	
	listMax = [thingList_i	count];
	if (!listMax)
		return;
	
	//
	//	Strip all things in list
	//
	for (k = 0;k < numthings;k++)
		for (j = 0;j < listMax; j++)
		{
			ts = [thingList_i	elementAt:j];
			if (ts->value == things[k].type)
				things[k].selected = -1;
		}

	[editworld_i	redrawWindows];
	[doomproject_i	setMapDirty:TRUE];
}

//===================================================================
//
//	Do actual Thing stripping from all maps
//
//===================================================================
- (IBAction)doStrippingAllMaps:sender
{
	int		k,j;
	NSInteger		listMax;
	thingstrip_t	*ts;
	
	listMax = [thingList_i	count];
	if (!listMax)
		return;
	
	[editworld_i	closeWorld];
	[doomproject_i	beginOpenAllMaps];
	
#ifdef REDOOMED
	// Bugfix: removed the semicolon at the end of the line (caused empty loop)
	while ([doomproject_i	openNextMap] == YES)
#else // Original
	while ([doomproject_i	openNextMap] == YES);
#endif
	{
		//
		//	Strip all things in list
		//
		for (k = 0;k < numthings;k++)
			for (j = 0;j < listMax; j++)
			{
				ts = [thingList_i	elementAt:j];
				if (ts->value == things[k].type)
					things[k].selected = -1;
			}

		[doomproject_i	saveDoomEdMapBSP:NULL];
	}
}

//===================================================================
//
//	Delete thing from Thing Stripping Panel
//
//===================================================================
- (IBAction)deleteThing:sender
{
	NSMatrix *matrix;
	NSInteger selRow;
	
	matrix = [thingBrowser_i	matrixInColumn:0];
	selRow = [matrix	selectedRow];
	if (selRow >= 0)
	{
		[matrix	removeRow:selRow];
		[thingList_i	removeElementAt:selRow];
	}
	[matrix	sizeToCells];
	[matrix	selectCellAtRow:-1 column:-1];
	[thingBrowser_i	reloadColumn:0];
}

//===================================================================
//
//	Add thing in Thing Panel to this list
//
//===================================================================
- (IBAction)addThing:sender
{
	thinglist_t		*t;
	thingstrip_t	ts;

	t =[thingpanel_i	getCurrentThingData];
	if (t == NULL)
	{
		NXBeep();
		return;
	}
	ts.value = t->value;
	strcpy(ts.desc,t->name);
	[thingList_i	addElement:&ts];
	[thingBrowser_i	reloadColumn:0];
}

//===================================================================
//
//	Delegate method called by "thingBrowser_i" when reloadColumn is invoked
//
//===================================================================
#ifdef REDOOMED
// Cocoa version
- (void) browser: (NSBrowser *) sender
        createRowsForColumn: (NSInteger) column
        inMatrix: (NSMatrix *) matrix
#else // Original
- (int)browser:sender  fillMatrix:matrix  inColumn:(int)column
#endif
{
	NSInteger	max, i;
	id	cell;
	thingstrip_t	*t;
	
	if (column > 0)
#ifdef REDOOMED
		return; // Cocoa version doesn't return a value
#else // Original
		return 0;
#endif
		
	max = [thingList_i	count];
	for (i = 0; i < max; i++)
	{
		t = [thingList_i	elementAt:i];
		[matrix	insertRow:i];
		cell = [matrix	cellAtRow:i	column:0];

#ifdef REDOOMED
		[cell	setStringValue:RDE_NSStringFromCString(t->desc)];
#else // Original
		[cell	setStringValue:t->desc];
#endif

		[cell setLeaf: YES];
		[cell setLoaded: YES];
		[cell setEnabled: YES];
	}

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return max;
#endif
}

@end
