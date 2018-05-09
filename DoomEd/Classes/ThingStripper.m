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
		[NSBundle loadNibNamed: @"ThingStripper"
						 owner: self];
		[thingStripPanel_i	setFrameUsingName:THINGSTRIPNAME];
		[thingStripPanel_i	setDelegate:self];

		thingList_i = [[CompatibleStorage alloc]
			initCount: 0
			elementSize: sizeof(thingstrip_t)
			description: NULL
		];
	}
	[thingBrowser_i	reloadColumn:0];
	[thingStripPanel_i	makeKeyAndOrderFront:NULL];
}

- (void)windowDidMiniaturize:(NSNotification *)notification
{
	NSWindow *window = [notification object];
	//[window setMiniwindowIcon:"DoomEd"];
	[window setMiniwindowTitle:@"ThingStrip"];
}

//
//	Empty list if window gets closed!
//
- (void)windowWillClose:(NSNotification *)notification
{
	[thingStripPanel_i	saveFrameUsingName:THINGSTRIPNAME];
	[thingList_i	empty];
}

//===================================================================
//
//	Do actual Thing stripping from all maps
//
//===================================================================
- (IBAction)doStrippingOneMap:sender
{
	int		k,j;
	int		listMax;
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
	int		listMax;
	thingstrip_t	*ts;
	
	listMax = [thingList_i	count];
	if (!listMax)
		return;
	
	[editworld_i	closeWorld];
	[doomproject_i	beginOpenAllMaps];
	
	while ([doomproject_i	openNextMap] == YES)
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
	id	matrix;
	NSInteger	selRow;
	
	matrix = [thingBrowser_i	matrixInColumn:0];
	selRow = [matrix	selectedRow];
	if (selRow >= 0)
	{
		[matrix	removeRowAtIndex:selRow];
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
	thinglist_t		t;
	thingstrip_t	ts;

	if (![thingpanel_i getCurrentThingData:&t])
	{
		NSBeep();
		return;
	}
	ts.value = t.value;
	strcpy(ts.desc,t.name);
	[thingList_i	addElement:&ts];
	[thingBrowser_i	reloadColumn:0];
}

//===================================================================
//
//	Delegate method called by "thingBrowser_i" when reloadColumn is invoked
//
//===================================================================
- (void)browser:(NSBrowser *)sender createRowsForColumn:(NSInteger)column inMatrix:(NSMatrix *)matrix
{
	NSInteger		max, i;
	NSBrowserCell	*cell;
	thingstrip_t	*t;
	
	if (column > 0)
		return;
		
	max = [thingList_i	count];
	for (i = 0; i < max; i++)
	{
		t = [thingList_i	elementAt:i];
		[matrix	insertRow:i];
		cell = [matrix	cellAtRow:i	column:0];
		[cell setStringValue:@(t->desc)];
		[cell setLeaf: YES];
		[cell setLoaded: YES];
		[cell setEnabled: YES];
	}
	//return max;
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column
{
	
}

@end
