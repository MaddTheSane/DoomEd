#import "Remapper.h"
#import	"DoomProject.h"
#import	"EditWorld.h"
#import	"TextureEdit.h"
#import "ps_quartz.h"

@implementation Remapper
//===================================================================
//
//	REMAPPER
//
//	Delegate methods required for Remapper to work:
//
//	- (char *)getOriginalName;
//	- (char *)getNewName;
//	- (int)doRemap:(char *)oldname to:(char *)newname;
//
//===================================================================
- (void)setFrameName: (NSString *)fname
	   setPanelTitle: (NSString *)ptitle
	 setBrowserTitle: (NSString *)btitle
	  setRemapString: (NSString *)rstring
		 setDelegate: (id)delegate
{
	frameName = fname;

	if (! remapPanel_i )
	{
		[NSBundle loadNibNamed: @"Remapper"
						 owner: self];

		storage_i = [ [CompatibleStorage alloc]
			initCount: 0
			elementSize: sizeof(type_t)
			description: NULL
		];

		[remapPanel_i setFrameUsingName:fname];
		[status_i setStringValue:@" "];
	}
	
	[remapString_i setStringValue:rstring];
	[browser_i		setTitle:btitle ofColumn:0];
	[remapPanel_i	setTitle:ptitle];
	delegate_i = delegate;
}

//===================================================================
//
//	Bring up panel
//
//===================================================================
- (void)showPanel
{
	[remapPanel_i	makeKeyAndOrderFront:NULL];
}

//===================================================================
//
//	Make delegate return string from source depending on which Get button was used
//
//===================================================================
- (IBAction)remapGetButtons:sender
{
	switch([sender	tag])
	{
		case 0:
			[original_i  setStringValue:[delegate_i getOriginalName]];
			break;
		case 1:
			[new_i  setStringValue:[delegate_i  getNewName]];
			break;
	}
}

//===================================================================
//
//	Add old & new texture names to list
//
//===================================================================
- (void)addToList: (NSString *) orgname to: (NSString *) newname
{
	if (!storage_i)
		return;

	[original_i setStringValue:orgname];
	[new_i setStringValue:newname];
	[self addToList:NULL];
}

- (IBAction)addToList:sender
{
	type_t		r,	*r2;
	NSInteger	i, max;

	r.orgname = [[original_i stringValue] uppercaseString];
	r.newname = [[new_i stringValue] uppercaseString];

	[original_i setStringValue: r.orgname];
	[new_i setStringValue: r.newname];

	//
	//	Check for duplicates
	//
	max = [storage_i count];
	for (i = 0;i < max; i++)
	{
		r2 = [storage_i elementAt:i];
		if ([r2->orgname compare: r.orgname] == 0
		 && [r2->newname compare: r.newname] == 0)
		{
			NSBeep ();
			return;
		}
	}
	
	[storage_i	addElement:&r];
	[browser_i	reloadColumn:0];
}

//===================================================================
//
//	Delete list entry
//
//===================================================================
- (IBAction)deleteFromList:sender
{
	NSInteger	selRow;
	
	matrix_i = [browser_i	matrixInColumn:0];
	selRow = [matrix_i		selectedRow];
	if (selRow < 0)
		return;
	[matrix_i		removeRowAtIndex:selRow];
	[matrix_i		sizeToCells];
	[matrix_i		selectCellAtRow:-1 column:-1];
	[storage_i	removeElementAt:selRow];
	[browser_i	reloadColumn:0];
}

//===================================================================
//
//	Clear out the entire list
//
//===================================================================
- (IBAction)clearList:sender
{
	if (NSRunAlertPanel(@"Warning!",
		@"Are you sure you want to clear the remapping list?",
		@"OK", @"Cancel", nil) == NSAlertAlternateReturn)
		return;

	[remapPanel_i	saveFrameUsingName:frameName];
	[storage_i		empty];
	[original_i		setStringValue:@" "];
	[new_i			setStringValue:@" "];
	[browser_i	reloadColumn:0];
}

//===================================================================
//
//	Actually do the remapping for current map
//
//===================================================================
- (IBAction)doRemappingOneMap:sender
{
	type_t	*r;
	NSInteger		index, max;
	unsigned int		linenum;
	NSString *oldname, *newname;
	NSString *string;
	
	max = [storage_i	count];
	if (!max)
	{
		NSBeep ();
		return;
	}

	linenum = 0;
	for (index = 0; index < max; index++)
	{
		r = [storage_i	elementAt:index];
		oldname = r->orgname;
		newname = r->newname;
		
		linenum += [delegate_i	doRemap:oldname to:newname];
	}

	string = [NSString stringWithFormat: @"%u total remappings performed.",
	                                     linenum];
	[ status_i setStringValue: string ];
	[ delegate_i finishUp ];
	[ doomproject_i	setMapDirty:TRUE];
}

//===================================================================
//
//	Actually do the remapping for ALL MAPS
//
//===================================================================
- (IBAction)doRemappingAllMaps:sender
{
	type_t	*r;
	NSInteger		index, max;
	unsigned int		linenum, total;
	NSString *oldname, *newname;
	NSString *string;

	[editworld_i	closeWorld];
	[doomproject_i	beginOpenAllMaps];
	max = [storage_i	count];
	if (!max)
	{
		NSBeep ();
		return;
	}
	total = 0;
	
	while ([doomproject_i	openNextMap] == YES)
	{
		linenum = 0;
		for (index = 0; index < max; index++)
		{
			r = [storage_i	elementAt:index];
			oldname = r->orgname;
			newname = r->newname;

			linenum += [delegate_i	doRemap:oldname to:newname];
		}

		string = [NSString stringWithFormat: @"%u remappings.",
		                                     linenum];
		total += linenum;
		[status_i setStringValue:string];
		[remapPanel_i makeKeyAndOrderFront:NULL];
		PSwait ();
		if (linenum)
			[ editworld_i	saveDoomEdMapBSP:NULL ];
	}

	string = [NSString stringWithFormat: @"%u total remappings performed.",
	                                     total];
	[status_i setStringValue: string];
	[delegate_i finishUp];
}

//===================================================================
//
//	Delegate methods
//
//===================================================================
- (void)windowDidMiniaturize:(NSNotification *)notification
{
	NSWindow *window = [notification object];
	//[window setMiniwindowIcon:"DoomEd"];
	[window setMiniwindowTitle:frameName];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	if ([self respondsToSelector:@selector(windowWillClose:)]) {
		[self windowWillClose:notification];
	}
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column
{
	NSString *string;
	type_t	*r;
	r = [storage_i	elementAt:row];

	
	string = [NSString stringWithFormat: @"%@ remaps to %@",
			  r->orgname, r->newname];
	
	[cell setStringValue:string];
	[cell setLeaf: YES];
	[cell setLoaded: YES];
	[cell setEnabled: YES];
}

- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column
{
	return storage_i.count;
}

@end
