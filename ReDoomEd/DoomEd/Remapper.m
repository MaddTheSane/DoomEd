// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "Remapper.h"
#import	"DoomProject.h"
#import	"EditWorld.h"
#import	"TextureEdit.h"

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
- setFrameName:(char *)fname
  setPanelTitle:(char *)ptitle
  setBrowserTitle:(char *)btitle
  setRemapString:(char *)rstring
  setDelegate:(id)delegate
{
	strcpy(frameName,fname);
	
	if (! remapPanel_i )
	{
		[NXApp 
			loadNibSection:	"Remapper.nib"
			owner:			self
			withNames:		NO
		];
		
		storage_i = [[	Storage		alloc]
					initCount:		0
					elementSize:	sizeof(type_t)
					description:	NULL];
		
#ifdef REDOOMED		
		[remapPanel_i	setFrameUsingName:RDE_NSStringFromCString(fname)];
		[status_i		setStringValue:@" "];
#else // Original
		[remapPanel_i	setFrameUsingName:fname];
		[status_i		setStringValue:" "];
#endif
	}
	
#ifdef REDOOMED
	[remapString_i	setStringValue:RDE_NSStringFromCString(rstring)];
	[browser_i		setTitle:RDE_NSStringFromCString(btitle) ofColumn:0];
	[remapPanel_i	setTitle:RDE_NSStringFromCString(ptitle)];
#else // Original
	[remapString_i	setStringValue:rstring];
	[browser_i		setTitle:btitle ofColumn:0];
	[remapPanel_i	setTitle:ptitle];
#endif	

	delegate_i = delegate;
	
	return self;
}

//===================================================================
//
//	Bring up panel
//
//===================================================================
- showPanel
{
	[remapPanel_i	makeKeyAndOrderFront:NULL];
	return self;
}

//===================================================================
//
//	Make delegate return string from source depending on which Get button was used
//
//===================================================================
- remapGetButtons:sender
{
	switch([sender	tag])
	{
		case 0:
#ifdef REDOOMED
			[original_i  setStringValue:RDE_NSStringFromCString([delegate_i getOriginalName])];
#else // Original
			[original_i  setStringValue:[delegate_i getOriginalName]];
#endif
			break;
		case 1:
#ifdef REDOOMED
			[new_i  setStringValue:RDE_NSStringFromCString([delegate_i  getNewName])];
#else // Original
			[new_i  setStringValue:[delegate_i  getNewName]];
#endif
			break;
	}
	return self;
}

//===================================================================
//
//	Add old & new texture names to list
//
//===================================================================
- addToList:(char *)orgname to:(char *)newname
{
	if (!storage_i)
		return self;

#ifdef REDOOMED
	[original_i	setStringValue:RDE_NSStringFromCString(orgname)];
	[new_i		setStringValue:RDE_NSStringFromCString(newname)];
#else // Original
	[original_i	setStringValue:orgname];
	[new_i		setStringValue:newname];
#endif

	[self			addToList:NULL];

	return self;
}

- addToList:sender
{
	type_t	r,	*r2;
	int		i, max;
		
#ifdef REDOOMED
	// prevent buffer overflows: strcpy() -> macroRDE_SafeCStringCopy()
	macroRDE_SafeCStringCopy(r.orgname, RDE_CStringFromNSString([original_i stringValue]));
	macroRDE_SafeCStringCopy(r.newname, RDE_CStringFromNSString([new_i stringValue]));
#else // Original		
	strcpy ( r.orgname, [original_i	stringValue] );
	strcpy ( r.newname, [new_i		stringValue] );
#endif
	
	strupr( r.orgname );
	strupr( r.newname );
	
#ifdef REDOOMED	
	[original_i	setStringValue:RDE_NSStringFromCString(r.orgname)];
	[new_i		setStringValue:RDE_NSStringFromCString(r.newname)];
#else // Original
	[original_i	setStringValue:r.orgname];
	[new_i		setStringValue:r.newname];
#endif
	
	//
	//	Check for duplicates
	//
	max = [storage_i	count];
	for (i = 0;i < max; i++)
	{
		r2 = [storage_i		elementAt:i];
		if (	(!strcmp(r2->orgname,r.orgname)) &&
			(!strcmp(r2->newname,r.newname))  )
			{
				NXBeep ();
				return self;
			}
	}
	
	[storage_i	addElement:&r];
	[browser_i	reloadColumn:0];
	
	return self;
}

//===================================================================
//
//	Delete list entry
//
//===================================================================
- deleteFromList:sender
{
	int	selRow;
	
	matrix_i = [browser_i	matrixInColumn:0];
	selRow = [matrix_i		selectedRow];
	if (selRow < 0)
		return self;
	[matrix_i		removeRowAt:selRow andFree:YES ];
	[matrix_i		sizeToCells];
	[matrix_i		selectCellAt:-1 :-1];
	[storage_i	removeElementAt:selRow];
	[browser_i	reloadColumn:0];
	
	return self;
}

//===================================================================
//
//	Clear out the entire list
//
//===================================================================
- clearList:sender
{
	if (NXRunAlertPanel("Warning!",
		"Are you sure you want\n"
		"to clear the remapping list?",
		"OK","Cancel",NULL) == NX_ALERTALTERNATE)
		return self;
		
#ifdef REDOOMED
	[remapPanel_i	saveFrameUsingName:RDE_NSStringFromCString(frameName)];
#else // Original		
	[remapPanel_i	saveFrameUsingName:frameName];
#endif

	[storage_i		empty];

#ifdef REDOOMED
	[original_i		setStringValue:@" "];
	[new_i			setStringValue:@" "];
#else // Original
	[original_i		setStringValue:" "];
	[new_i			setStringValue:" "];
#endif

	[browser_i	reloadColumn:0];
	
	return self;
}

//===================================================================
//
//	Actually do the remapping for current map
//
//===================================================================
- doRemappingOneMap:sender
{
	type_t	*r;
	int		index, max;
	unsigned int		linenum;
	char		*oldname, *newname, string[64];
	
	max = [storage_i	count];
	if (!max)
	{
		NXBeep ();
		return self;
	}

	linenum = 0;
	for (index = 0; index < max; index++)
	{
		r = [storage_i	elementAt:index];
		oldname = r->orgname;
		newname = r->newname;
		
		linenum += [delegate_i	doRemap:oldname to:newname];
	}
		
	sprintf ( string, "%u total remappings performed.", linenum );

#ifdef REDOOMED
	[ status_i	setStringValue: RDE_NSStringFromCString(string) ];
#else // Original
	[ status_i	setStringValue: string ];
#endif

	[ delegate_i	finishUp ];
	[ doomproject_i	setDirtyMap:TRUE];
	
	return self;
}

//===================================================================
//
//	Actually do the remapping for ALL MAPS
//
//===================================================================
- doRemappingAllMaps:sender
{
	type_t	*r;
	int		index, max;
	unsigned int		linenum, total;
	char		*oldname, *newname, string[64];
	
	[editworld_i	closeWorld];
	[doomproject_i	beginOpenAllMaps];
	max = [storage_i	count];
	if (!max)
	{
		NXBeep ();
		return self;
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
			
		sprintf ( string, "%u remappings.", linenum );
		total += linenum;

#ifdef REDOOMED
		[ status_i	setStringValue:RDE_NSStringFromCString(string) ];
#else // Original
		[ status_i	setStringValue:string ];
#endif

		[ remapPanel_i	makeKeyAndOrderFront:NULL];
		NXPing ();
		if (linenum)
			[ editworld_i	saveDoomEdMapBSP:NULL ];
	}
	
	sprintf ( string, "%u total remappings performed.", total );

#ifdef REDOOMED
	[ status_i	setStringValue: RDE_NSStringFromCString(string) ];
#else // Original
	[ status_i	setStringValue: string ];
#endif

	[ delegate_i	finishUp ];
	
	return self;
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
	char		string[128];
	type_t	*r;
	
	max = [storage_i	count];
	for (i = 0; i < max; i++)
	{
		r = [storage_i	elementAt:i];
		[matrix	addRow];
		cell = [matrix	cellAtRow:i	column:0];
		
		strcpy ( string, r->orgname );
		strcat ( string, " remaps to " );
		strcat ( string, r->newname );
		
#ifdef REDOOMED
		[cell	setStringValue:RDE_NSStringFromCString(string)];
#else // Original		
		[cell	setStringValue:string];
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
