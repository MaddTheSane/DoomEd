// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "Remapper.h"
#import	"DoomProject.h"
#import	"EditWorld.h"
#import	"TextureEdit.h"

@interface RemapperObject : NSObject
@property (copy) NSString *originalName;
@property (copy) NSString *theNewName;
@end

@implementation RemapperObject

- (void)dealloc
{
	[_originalName release];
	[_theNewName release];
	
	[super dealloc];
}

- (BOOL)isEqual:(id)object
{
	RemapperObject *obj = object;
	if (![object isKindOfClass:[RemapperObject class]]) {
		return NO;
	}
	
	if (![_originalName isEqualToString:obj.originalName]) {
		return NO;
	}
	if (![_theNewName isEqualToString:obj.theNewName]) {
		return NO;
	}
	
	return YES;
}

@end

@implementation Remapper {
	NSMutableArray<RemapperObject*> *storage_i;
}
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
- setFrameName:(char *)fname
  setPanelTitle:(char *)ptitle
  setBrowserTitle:(char *)btitle
  setRemapString:(char *)rstring
  setDelegate:(id)delegate
{
	[self setFrameName:RDE_NSStringFromCString(fname) panelTitle:RDE_NSStringFromCString(ptitle) browserTitle:RDE_NSStringFromCString(btitle) remapString:RDE_NSStringFromCString(rstring) delegate:delegate];
	return self;
}

- (void)setFrameName:(NSString *)fname
		  panelTitle:(NSString *)ptitle
		browserTitle:(NSString *)btitle
		 remapString:(NSString *)rstring
			delegate:(id<Remapper>)delegate
{
	[frameName release];
	frameName = [fname copy];
	
	if (! remapPanel_i )
	{
		[NXApp 
			loadNibSection:	"Remapper.nib"
			owner:			self
			withNames:		NO
		];
		
		storage_i = [[NSMutableArray alloc] init];
		
#ifdef REDOOMED		
		[remapPanel_i	setFrameUsingName:fname];
		[status_i		setStringValue:@" "];
#else // Original
		[remapPanel_i	setFrameUsingName:fname];
		[status_i		setStringValue:" "];
#endif
	}
	
#ifdef REDOOMED
	[remapString_i	setStringValue:rstring];
	[browser_i		setTitle:btitle ofColumn:0];
	[remapPanel_i	setTitle:ptitle];
#else // Original
	[remapString_i	setStringValue:rstring];
	[browser_i		setTitle:btitle ofColumn:0];
	[remapPanel_i	setTitle:ptitle];
#endif	

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
#ifdef REDOOMED
			[original_i  setStringValue:[delegate_i originalName]];
#else // Original
			[original_i  setStringValue:[delegate_i getOriginalName]];
#endif
			break;
		case 1:
#ifdef REDOOMED
			[new_i  setStringValue:[delegate_i newName]];
#else // Original
			[new_i  setStringValue:[delegate_i  getNewName]];
#endif
			break;
	}
}

//===================================================================
//
//	Add old & new texture names to list
//
//===================================================================
- (void)addToList:(char *)orgname to:(char *)newname
{
	[self addToListFromName:@(orgname) toName:@(newname)];
}

- (void)addToListFromName:(NSString *)orgname toName:(NSString *)newname;
{
	if (!storage_i)
		return;

#ifdef REDOOMED
	[original_i	setStringValue:orgname];
	[new_i		setStringValue:newname];
#else // Original
	[original_i	setStringValue:orgname];
	[new_i		setStringValue:newname];
#endif

	[self			addToList:NULL];
}

- (IBAction)addToList:sender
{
	NSInteger i, max;
	RemapperObject *r = [[RemapperObject alloc] init], *r2;
		
	r.originalName = original_i.stringValue.uppercaseString;
	r.theNewName = new_i.stringValue.uppercaseString;
	
	
#ifdef REDOOMED	
	[original_i	setStringValue:r.originalName];
	[new_i		setStringValue:r.theNewName];
#else // Original
	[original_i	setStringValue:r.orgname];
	[new_i		setStringValue:r.newname];
#endif
	
	//
	//	Check for duplicates
	//
	max = [storage_i	count];
	for (i = 0;i < max; i++) {
		r2 = [storage_i objectAtIndex:i];
		if ([r2 isEqual:r]) {
			NSBeep ();
			[r release];
			return;
		}
	}
	
	[storage_i addObject:r];
	[r release];
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
	[matrix_i		removeRow:selRow];
	[matrix_i		sizeToCells];
	[matrix_i		selectCellAtRow:-1 column:-1];
	[storage_i removeObjectAtIndex:selRow];
	[browser_i	reloadColumn:0];
}

//===================================================================
//
//	Clear out the entire list
//
//===================================================================
- (IBAction)clearList:sender
{
	if (NSRunAlertPanel(NSLocalizedString(@"Warning!", @"Warning!"),
		@"Are you sure you want\n"
		"to clear the remapping list?",
						NSLocalizedString(@"OK", @"OK"),NSLocalizedString(@"Cancel", @"Cancel"),NULL) == NSAlertAlternateReturn)
		return;
		
#ifdef REDOOMED
	[remapPanel_i	saveFrameUsingName:frameName];
#else // Original		
	[remapPanel_i	saveFrameUsingName:frameName];
#endif

	[storage_i removeAllObjects];

#ifdef REDOOMED
	[original_i		setStringValue:@" "];
	[new_i			setStringValue:@" "];
#else // Original
	[original_i		setStringValue:" "];
	[new_i			setStringValue:" "];
#endif

	[browser_i	reloadColumn:0];
}

//===================================================================
//
//	Actually do the remapping for current map
//
//===================================================================
- (IBAction)doRemappingOneMap:sender
{
	RemapperObject	*r;
	NSInteger		index, max;
	unsigned int		linenum;
	NSString		*oldname, *newname, *string;
	
	max = [storage_i	count];
	if (!max)
	{
		NSBeep ();
		return;
	}

	linenum = 0;
	for (index = 0; index < max; index++)
	{
		r = [storage_i	objectAtIndex:index];
		oldname = r.originalName;
		newname = r.theNewName;
		
		linenum += [delegate_i	doRemapFromName:oldname toName:newname];
	}
		
	string = [NSString localizedStringWithFormat:@"%u total remappings performed.", linenum];

	[ status_i setStringValue:string];

	[ delegate_i	finishUp ];
	[ doomproject_i	setMapDirty:TRUE];
}

//===================================================================
//
//	Actually do the remapping for ALL MAPS
//
//===================================================================
- (IBAction)doRemappingAllMaps:sender
{
	RemapperObject	*r;
	NSInteger		index, max;
	unsigned int		linenum, total;
	NSString		*oldname, *newname, *string;
	
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
			r = [storage_i	objectAtIndex:index];
			oldname = r.originalName;
			newname = r.theNewName;
			
			linenum += [delegate_i	doRemapFromName:oldname toName:newname];
		}
			
		string = [NSString localizedStringWithFormat:@"%u remappings.", linenum];
		total += linenum;

#ifdef REDOOMED
		[ status_i	setStringValue:string];
#else // Original
		[ status_i	setStringValue:string ];
#endif

		[ remapPanel_i	makeKeyAndOrderFront:NULL];
		NXPing ();
		if (linenum)
			[ editworld_i	saveDoomEdMapBSP:NULL ];
	}
	
	string = [NSString localizedStringWithFormat:@"%u total remappings performed.", total];

#ifdef REDOOMED
	[ status_i	setStringValue: string ];
#else // Original
	[ status_i	setStringValue: string ];
#endif

	[ delegate_i	finishUp ];
}

//===================================================================
//
//	Delegate methods
//
//===================================================================

#ifndef REDOOMED // Original (Disable for ReDoomEd - unused)
- windowDidMiniaturize:sender
{
	[sender	setMiniwindowIcon:"DoomEd"];
	[sender	setMiniwindowTitle:frameName];
	
	return self;
}

- appWillTerminate:sender
{
	[self	windowWillClose:NULL];
	return self;
}
#endif // Original (Disable for ReDoomEd)

// Cocoa version
- (void) browser: (NSBrowser *) sender
        createRowsForColumn: (NSInteger) column
        inMatrix: (NSMatrix *) matrix
{
	const NSInteger max = [storage_i count];
	for (NSInteger i = 0; i < max; i++)
	{
		RemapperObject *r = [storage_i objectAtIndex:i];
		[matrix	addRow];
		id cell = [matrix cellAtRow:i column:0];
		
		NSString *string = [NSString stringWithFormat:NSLocalizedString(@"%@ remaps to %@", @"%@ remaps to %@"), r.originalName, r.theNewName];
		
		[cell setStringValue:string];
		[cell setLeaf: YES];
		[cell setLoaded: YES];
		[cell setEnabled: YES];
	}
}

- (void)dealloc
{
	[frameName release];
	frameName = nil;
	
	[super dealloc];
}

@end
