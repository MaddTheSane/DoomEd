// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "PreferencePanel.h"
#import "MapWindow.h"
#import "EditWorld.h"
#import "ThingPanel.h"
#import	"ThingPalette.h"
#import	"ThingWindow.h"
#import	"TextureEdit.h"		// for strupr()
#import "ReDoomEd-Swift.h"

id	thingpanel_i;

@implementation ThingPanel

/*
=====================
=
= init
=
=====================
*/

- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	thingpanel_i = self;
	window_i = NULL;		// until nib is loaded
	masterList_i = [[Storage	alloc]
			initCount:		0
			elementSize:	sizeof(thinglist_t)
			description:	NULL];
			
	diffDisplay = DIFF_ALL;
	
#ifdef REDOOMED
	// the initial states of the panel's difficulty checkboxes are copied from the bottom
	// three bits of basething.options; set those 3 bits so the checkboxes will initially
	// be on (checked) instead of off (unchecked)
	basething.options |= 0x7;
#endif

	return self;
}

- emptyThingList
{
	[masterList_i	empty];
	return self;
}

/*
==============
=
= menuTarget:
=
==============
*/

- (IBAction)menuTarget:sender
{
	if (!window_i)
	{
		[NXApp 
			loadNibSection:	"thing.nib"
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

		[window_i	setFrameUsingName:THINGNAME];
		[window_i	setDelegate:self];
		[thingBrowser_i	reloadColumn:0];
		[diffDisplay_i	selectCellAtRow:diffDisplay column:0];

#ifdef REDOOMED
		[count_i	setStringValue:@" "];
		[(ThingWindow *) window_i setParent:self];
#else // Original
		[count_i	setStringValue:" "];
		[window_i	setParent:self];
#endif
	}

#ifdef REDOOMED
	// ThingPanel's control values may be out of date, since ThingPanel's implementation
	// of the windowDidUpdate: delegate method (below) is disabled for ReDoomEd (Cocoa
	// calls that delegate method too often - during every event - even preventing
	// textfields from being edited because windowDidUpdate:'s call to updateInspector:
	// restores all textfields to their current (pre-edit) values after each keypress
	// event), and other calls to updateInspector: pass NO (don't update if the panel's
	// hidden), so an updateInspector: call was added here, passing YES to force the panel
	// to update before showing it.
	[self updateInspector: YES];
#endif

	[window_i makeKeyAndOrderFront:self];
}

#ifndef REDOOMED // Original (Disable for ReDoomEd - unused)
- windowDidMiniaturize:sender
{
	[sender	setMiniwindowIcon:"DoomEd"];
	[sender	setMiniwindowTitle:"Things"];
	return self;
}
#endif


- saveFrame
{
	if (window_i)
		[window_i	saveFrameUsingName:THINGNAME];
	return self;
}

- pgmTarget
{
	if (!window_i)
		[self	menuTarget:NULL];
	else
		[window_i	orderFront:NULL];
	return self;
}

- (thinglist_t *)getCurrentThingData
{
#ifdef REDOOMED
	// Bugfix: make 'thing' static so the return value doesn't point to
	// a temporary stack value
	static thinglist_t thing;
#else // Original
	thinglist_t		thing;
#endif
	
	if (!fields_i)
	{
		NXBeep();
		return NULL;
	}
		
	thing.value = [fields_i		intValueAt:1];

#ifdef REDOOMED
	// prevent buffer overflows: strcpy() -> macroRDE_SafeCStringCopy()
	macroRDE_SafeCStringCopy(thing.name, RDE_CStringFromNSString([nameField_i stringValue]));
	macroRDE_SafeCStringCopy(thing.iconname, RDE_CStringFromNSString([iconField_i stringValue]));
#else // Original
	strcpy(thing.name,[nameField_i stringValue]);
	strcpy(thing.iconname,[iconField_i	stringValue]);
#endif

	return &thing;
}

//===================================================================
//
//	Report the difficulty of Things to view
//
//===================================================================
- (int)getDifficultyDisplay
{
	return diffDisplay;
}

//===================================================================
//
//	Change the difficulty of Things to view
//
//===================================================================
- (IBAction)changeDifficultyDisplay:sender
{
	id				cell;
	
	//
	//	Handle redrawing Edit windows for diff. change
	//
	cell = [sender selectedCell];
	diffDisplay = [cell tag];
	[editworld_i	redrawWindows];
	[self	countCurrentThings];
}

- currentThingCount
{
	[self countCurrentThings];
	return self;
}

//===================================================================
//
//	Display # of Things that match currently selected type
//
//===================================================================
- (void)countCurrentThings
{
	NSInteger		max;
	int				j;
	thinglist_t		*t;
	worldthing_t	*thing;
	int				count;

	//
	//	Count up how many of currently selected Thing there is
	//
	if (diffDisplay == DIFF_ALL)
	{
#ifdef REDOOMED
		[count_i	setStringValue:@"-"];
#else // Original
		[count_i	setStringValue:"-"];
#endif

		return;
	}
		
	max = [masterList_i	count];
	t = [self	getCurrentThingData];
	count = 0;
	thing = &things[0];

	for (j = 0;j < numthings; j++,thing++)
		if (t->value == thing->type)
		{
			if ((thing->options&1)-1 == diffDisplay)
				count++;
			else
			if (((thing->options&2)-1) == diffDisplay )
				count++;
			else
			if (((thing->options&4)-2) == diffDisplay )
				count++;
		}

	[count_i	setIntValue:count];
}

//===================================================================
//
//	Select the Thing that has icon "name"
//
//===================================================================
- selectThingWithIcon:(char *)name
{
	int				max;
	int				i;
	thinglist_t		*t;
	NSMatrix		*matrix;
	
	max = [masterList_i	count];
	for (i = 0;i < max; i++)
	{
		t = [masterList_i	elementAt:i];
		if (!strcasecmp(t->iconname,name))
		{
			[self	fillDataFromThing:t];
			matrix = [thingBrowser_i	matrixInColumn:0];
			[matrix	selectCellAtRow:i column:0];
			[matrix	scrollCellToVisibleAtRow:i column:0];
			return self;
		}
	}
	
	return self;
}

//===================================================================
//
//	Unlink icon from this Thing
//
//===================================================================
- (IBAction)unlinkIcon:sender
{
#ifdef REDOOMED
	[iconField_i	setStringValue:@"NOICON"];
#else // Original
	[iconField_i	setStringValue:"NOICON"];
#endif

	[updateButton_i	performClick:self];
}

//===================================================================
//
//	Assign icon selected in Thing Palette to current thing data
//
//===================================================================
- (IBAction)assignIcon:sender
{
	int		iconnum;
	icon_t	*icon;
	
	iconnum = [thingPalette_i	currentIcon];
	if (iconnum < 0)
	{
		NXBeep();
		return;
	}
	icon = [thingPalette_i	getIcon:iconnum];

#ifdef REDOOMED
	[iconField_i	setStringValue:RDE_NSStringFromCString(icon->name)];
#else // Original
	[iconField_i	setStringValue:icon->name];
#endif

	[updateButton_i	performClick:self];
}

//===================================================================
//
//	Verify a correct icon name input
//
//===================================================================
- (IBAction)verifyIconName:sender
{
	char	name[10];
	int		which;
	
#ifdef REDOOMED
	// prevent buffer overflows: strcpy() -> macroRDE_SafeCStringCopy()
	macroRDE_SafeCStringCopy(name, RDE_CStringFromNSString([iconField_i stringValue]));
#else // Original	
	strcpy(name,[iconField_i	stringValue]);
#endif

	strupr(name);
	which = [thingPalette_i	findIcon:name];
	if (which < 0)
	{
		NXBeep();

#ifdef REDOOMED
		[iconField_i	setStringValue:@"NOICON"];
#else // Original
		[iconField_i	setStringValue:"NOICON"];
#endif

		return;
	}

#ifdef REDOOMED
	[iconField_i	setStringValue:RDE_NSStringFromCString(name)];
#else // Original
	[iconField_i	setStringValue:name];
#endif
}

//===================================================================
//
//	Suggest a new type for a new Thing
//
//===================================================================
- (IBAction)suggestNewType:sender
{
	int	num,i,found,max;
	
	max = [masterList_i	count];
	for (num = 1;num < 10000;num++)
	{
		found = 0;
		for (i = 0;i < max;i++)
			if (((thinglist_t *)[masterList_i	elementAt:i])->value == num)
			{
				found = 1;
				break;
			}
		if (!found)
		{
			[fields_i	setIntValue:num	at:1];
			return;
		}
	}
}

//
// delegate method called by "thingBrowser_i"
//
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
	thinglist_t		*t;
	
	if (column > 0)
#ifdef REDOOMED
		return; // Cocoa version doesn't return a value
#else // Original
		return 0;
#endif
		
	[self	sortThings];
	max = [masterList_i	count];
	for (i = 0; i < max; i++)
	{
		t = [masterList_i	elementAt:i];
		[matrix	insertRow:i];
		cell = [matrix cellAtRow:i column:0];

#ifdef REDOOMED
		[cell	setStringValue:RDE_NSStringFromCString(t->name)];
#else // Original
		[cell	setStringValue:t->name];
#endif

		[cell setLeaf: YES];
		[cell setLoaded: YES];
		[cell setEnabled: YES];
	}

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return max;
#endif
}

//
// sort the thing list
//
- (void)sortThings
{
	id	cell;
	NSMatrix *matrix;
	NSInteger	max,i,j,flag, which;
	thinglist_t		*t1, *t2, tt1, tt2;
	char		name[32] = "\0";
	
	cell = [thingBrowser_i	selectedCell];
	if (cell)
#ifdef REDOOMED
		// prevent buffer overflows: strcpy() -> macroRDE_SafeCStringCopy()
		macroRDE_SafeCStringCopy(name, RDE_CStringFromNSString([cell stringValue]));
#else // Original
		strcpy(name,[cell	stringValue]);
#endif

	max = [masterList_i	count];
	
	do
	{
		flag = 0;
		for (i = 0;i < max; i++)
		{
			t1 = [masterList_i	elementAt:i];
			for (j = i + 1;j < max;j++)
			{
				t2 = [masterList_i	elementAt:j];
				if (strcasecmp(t2->name,t1->name) < 0)
				{
					tt1 = *t1;
					tt2 = *t2;
					[masterList_i	replaceElementAt:j  with:&tt1];
					[masterList_i	replaceElementAt:i  with:&tt2];
					flag = 1;
					break;
				}
			}
		}
	} while(flag);
	
	which = [self	findThing:name];
	if (which != NSNotFound)
	{
		matrix = [thingBrowser_i matrixInColumn:0];
		[matrix	selectCellAtRow:which column:0];
		[matrix	scrollCellToVisibleAtRow:which column:0];
	}			
}

//
// update current thing with current data
//
- (IBAction)updateThingData:sender
{
	id			cell;
	NSInteger	which;
	thinglist_t	*t;
#ifdef REDOOMED
	NXColor oldColor, newColor;
#endif
	
	cell = [thingBrowser_i		selectedCell];
	if (!cell)
	{
		NXBeep();
		return;
	}

#ifdef REDOOMED
	which = [self	findThing:(char *)RDE_CStringFromNSString([cell stringValue])];
#else // Original
	which = [self	findThing:(char *)[cell	stringValue]];
#endif

	t = [masterList_i	elementAt:which];

#ifdef REDOOMED
	oldColor = t->color;
#endif

	[self	fillThingData:t];

#ifdef REDOOMED
	newColor = t->color;
#endif

	[thingBrowser_i	reloadColumn:0];
	[[thingBrowser_i	matrixInColumn:0]
	 selectCellAtRow:which == NSNotFound ? -1 : which  column:0];
	[doomproject_i	setProjectDirty:TRUE];

#ifdef REDOOMED
	if (memcmp(&oldColor, &newColor, sizeof(NXColor)))
	{
		// thing color changed - refresh the mapviews
		[editworld_i redrawWindows];
	}
#endif
}

//
// take data from input fields and update thing data
//
- fillThingData:(thinglist_t *)thing
{
	thing->angle = [fields_i		intValueAt:0];
	thing->value = [fields_i		intValueAt:1];
	[self	confirmCorrectNameEntry:NULL];

#ifdef REDOOMED
	// prevent buffer overflows: strcpy() -> macroRDE_SafeCStringCopy()
	macroRDE_SafeCStringCopy(thing->name, RDE_CStringFromNSString([nameField_i stringValue]));
#else // Original
	strcpy(thing->name,[nameField_i	stringValue]);
#endif

	thing->option = [ambush_i	intValue]<<3;
	thing->option |= ([network_i	intValue]&1)<<4;
	thing->option |= [[difficulty_i cellAtRow:0 column:0] intValue]&1;
	thing->option |= ([[difficulty_i cellAtRow:1 column:0] intValue]&1)<<1;
	thing->option |= ([[difficulty_i cellAtRow:2 column:0] intValue]&1)<<2;

#ifdef REDOOMED
	thing->color = RDE_NXColorFromNSColor([thingColor_i color]);
	// prevent buffer overflows: strcpy() -> macroRDE_SafeCStringCopy()
	macroRDE_SafeCStringCopy(thing->iconname,
	                            RDE_CStringFromNSString([iconField_i stringValue]));
#else // Original
	thing->color = [thingColor_i	color];
	strcpy(thing->iconname,[iconField_i	stringValue]);
#endif

	if (!thing->iconname[0])
		strcpy(thing->iconname,"NOICON");
	return self;
}

//
// corrects any wrongness in namefield
//
- (IBAction)confirmCorrectNameEntry:sender
{
	char		name[32];
	int	i;

	bzero(name,32);

#ifdef REDOOMED
	if ([[nameField_i stringValue] length] > 31)
		strncpy(name,RDE_CStringFromNSString([nameField_i stringValue]),31);
	else
		strcpy(name,RDE_CStringFromNSString([nameField_i stringValue]));
#else // Original
	if (strlen([nameField_i	stringValue]) > 31)
		strncpy(name,[nameField_i	stringValue],31);
	else
		strcpy(name,[nameField_i	stringValue]);
#endif		
		
	for (i = 0; i < strlen(name);i++)
		if (name[i] == ' ')
			name[i] = '_';

#ifdef REDOOMED
	[nameField_i	setStringValue:RDE_NSStringFromCString(name)];
#else // Original
	[nameField_i	setStringValue:name];
#endif
}

//
// fill-in the information for a worldthing_t
//
- (void)getThing:(worldthing_t	*)thing
{
	thing->angle = [fields_i	intValueAt:0];
	thing->type = [fields_i	intValueAt:1];
	thing->options = [ambush_i	intValue]<<3;
	thing->options |= ([network_i	intValue]&1)<<4;
	thing->options |= [[difficulty_i	cellAtRow:0 column:0] intValue]&1;
	thing->options |= ([[difficulty_i	cellAtRow:1 column:0] intValue]&1)<<1;
	thing->options |= ([[difficulty_i	cellAtRow:2 column:0] intValue]&1)<<2;
}

//
// user selected a thing in the map; reflect the selection in the thingpanel
//
- (void)setThing:(worldthing_t *)thing
{
	int	which;
	thinglist_t		*t;
	
	which = [self	searchForThingType:thing->type];
	if (which >= 0)
	{
		t = [masterList_i	elementAt:which];
		t->option = thing->options;
		t->angle = thing->angle;
		
		[self	fillAllDataFromThing:t];
		[self	scrollToItem:which];
		[thingPalette_i	setCurrentIcon:[thingPalette_i	findIcon:t->iconname]];
	}
}

@synthesize thingList=masterList_i;

- scrollToItem:(NSInteger)which
{
	NSMatrix *matrix;
	
	matrix = [thingBrowser_i matrixInColumn:0];
	[matrix	selectCellAtRow:which column:0];
	[matrix	scrollCellToVisibleAtRow:which column:0];
	return self;
}

- (IBAction)setAngle:sender
{
	[[fields_i cellAtIndex:0] setIntegerValue:[[sender selectedCell] tag]];
	[self		formTarget:NULL];
}

- (NXColor)getThingColor:(int)type
{
	NSInteger	index;
	
	index = [self  searchForThingType:type];
	if (index != NSNotFound)
		return [prefpanel_i colorFor: SELECTED_C];
	return	((thinglist_t *)[masterList_i	elementAt:index])->color;
}

//
// you know the thing's type, but don't know the name!
//
- (NSInteger)searchForThingType:(int)type
{
	NSInteger	max,i;
	thinglist_t		*t;
	
	max = [masterList_i	count];
	for (i = 0;i < max;i++)
	{
		t = [masterList_i	elementAt:i];
		if (t->value == type)
			return i;
	}
	return NSNotFound;
}

//
// fill data from thing
//
- (void)fillDataFromThing:(thinglist_t *)thing
{
	[fields_i	setIntValue:thing->value	at:1];

#ifdef REDOOMED
	[nameField_i	setStringValue:RDE_NSStringFromCString(thing->name)];
	[thingColor_i	setColor:RDE_NSColorFromNXColor(thing->color)];
	[iconField_i	setStringValue:RDE_NSStringFromCString(thing->iconname)];
#else // Original
	[nameField_i	setStringValue:thing->name];
	[thingColor_i	setColor:thing->color];
	[iconField_i	setStringValue:thing->iconname];
#endif
	
	basething.type = thing->value;
}

//
// fill ALL data from thing
//
- fillAllDataFromThing:(thinglist_t *)thing
{
	[self	fillDataFromThing:thing];
	
	[fields_i	setIntValue:thing->angle	at:0];
	[ambush_i	setIntValue:((thing->option)>>3)&1];
	[network_i	setIntValue:((thing->option)>>4)&1];
	[[difficulty_i cellAtRow:0 column:0] setIntValue:(thing->option)&1];
	[[difficulty_i cellAtRow:1 column:0] setIntValue:((thing->option)>>1)&1];
	[[difficulty_i cellAtRow:2 column:0] setIntValue:((thing->option)>>2)&1];
	
	basething.angle = thing->angle;
	basething.options = thing->option;
	
	return self;
}

//
// Add "type" to thing list
//
- (IBAction)addThing:sender
{
	thinglist_t		t;
	NSInteger	which;
	NSMatrix	*matrix;

	[self	fillThingData:&t];
	
	//
	// check for duplicate name
	//
	if ([self	findThing:t.name] != NSNotFound)
	{
		NXBeep();
		NXRunAlertPanel("Oops!",
			"You already have a THING by that name!","OK",NULL,NULL,NULL);
		return;
	}
	
	[masterList_i	addElement:&t];
	[thingBrowser_i	reloadColumn:0];
	which = [self	findThing:t.name];
	matrix = [thingBrowser_i	matrixInColumn:0];
	[matrix	selectCellAtRow:which column:0];
	[matrix	scrollCellToVisibleAtRow:which column:0];
	[doomproject_i	setProjectDirty:TRUE];
}

#if 0
//
// delete thing from list.
// Data in "name" and "type" must match element in list.
//
- delThing:sender
{
	int	which;
	
	if ((which = [self	findThing:(char *)[nameField_i  stringValue]]) != -1)
	{
		[masterList_i	removeElementAt:which];
		[thingBrowser_i	reloadColumn:0];
	}
	return self;
}
#endif

//
// return index of thing in masterList. "string" is used for search thru list.
//
- (NSInteger)findThing:(char *)string
{
	NSInteger	max, i;
	thinglist_t		*t;
	
	max = [masterList_i	count];
	for (i = 0;i < max; i++)
	{
		t = [masterList_i	elementAt:i];
		if (!strcasecmp(t->name,string))
			return i;
	}
	return NSNotFound;
}

- (thinglist_t *)getThingData:(NSInteger)index
{
	return [masterList_i	elementAt:index];		
}

//
// user chose an item in the thingBrowser_i.
// stick the info in the "name" and "type" fields.
//
- (IBAction)chooseThing:sender
{
	id			cell;
	NSInteger	which;
	thinglist_t	*t;
	
	cell = [sender	selectedCell];
	if (!cell)
		return;
		
#ifdef REDOOMED
	which = [self findThing:(char *)RDE_CStringFromNSString([cell stringValue])];
#else // Original
	which = [self	findThing:(char *)[cell	stringValue]];
#endif

	if (which == NSNotFound)
	{
		NXBeep();
		printf("Whoa! Can't find that thing!\n");
		return;
	}

	t = [masterList_i	elementAt:which];
	[self	fillDataFromThing:t];
	[self	formTarget:NULL];
	which = [thingPalette_i	findIcon:t->iconname];
	if (which != NSNotFound)
		[thingPalette_i	setCurrentIcon:which];
}

- (BOOL) readThing:(thinglist_t *)thing	from:(FILE *)stream
{
	float	r,g,b;
	
#ifdef REDOOMED
	// prevent buffer overflows: specify string buffer sizes in *scanf() format strings
	if (fscanf(stream,"%31s = %d %d %d (%f %f %f) %8s\n",
#else // Original
	if (fscanf(stream,"%s = %d %d %d (%f %f %f) %s\n",
#endif
			thing->name,&thing->angle,&thing->value,&thing->option,
			&r,&g,&b,thing->iconname) != 8)
		return NO;
	thing->color = NXConvertRGBToColor(r,g,b);
	return YES;
}

- (void)writeThing:(thinglist_t *)thing	from:(FILE *)stream
{
	float	r,g,b;
	
	NXConvertColorToRGB(thing->color,&r,&g,&b);
	fprintf(stream,"%s = %d %d %d (%f %f %f) %s\n",thing->name,thing->angle,thing->value,
			thing->option,r,g,b,thing->iconname);
}

//
// update the things.dsp file (when project is saved/loaded)
//
- (void)updateThingsDSP:(FILE *)stream
{
	thinglist_t		t,*t2;
	NSInteger	count, i, found;
	
	//
	// read things out of the file, only adding new things to the current list
	//
	int tmpInt;
	if (fscanf (stream, "numthings: %d\n", &tmpInt) == 1)
	{
		count = tmpInt;
		for (i = 0; i < count; i++)
		{
			[self	readThing:&t	from:stream];
			found = [self	findThing:t.name];
			if (found == NSNotFound)
			{
				[masterList_i	addElement:&t];
				[doomproject_i	setProjectDirty:TRUE];
			}
		}
		[thingBrowser_i	reloadColumn:0];

		//
		// now, write out the new file!
		//
		count = [masterList_i	count];
		fseek (stream, 0, SEEK_SET);
		fprintf (stream, "numthings: %ld\n",(long)count);
		for (i = 0; i < count; i++)
		{
			t2 = [masterList_i	elementAt:i];
			[self	writeThing:t2	from:stream];
		}
	}
	else
		fprintf(stream,"numthings: %d\n",0);
}
	
/*
==============
=
= updateInspector
=
= call with force == YES to update into a window while it is off screen, otherwise
= no updating is done if not visible
=
==============
*/

- updateInspector: (BOOL)force
{
	if (!force && ![window_i isVisible])
		return self;

	[window_i disableFlushWindow];
	
	[fields_i setIntValue: basething.angle at: 0];
	[fields_i setIntValue: basething.type at: 1];
	[ambush_i	setIntValue:((basething.options)>>3)&1];
	[network_i	setIntValue:((basething.options)>>4)&1];
	[[difficulty_i	cellAtRow:0 column:0] setIntValue:(basething.options)&1];
	[[difficulty_i	cellAtRow:1 column:0] setIntValue:((basething.options)>>1)&1];
	[[difficulty_i	cellAtRow:2 column:0] setIntValue:((basething.options)>>2)&1];
	
	[window_i reenableFlushWindow];

#ifdef REDOOMED
	// avoid unnecessary flushing
	[window_i flushWindowIfNeeded];
#else // Original
	[window_i flushWindow];
#endif
	
	return self;
}

/*
==============
=
= formTarget:
=
= The user has edited something in a form cell
=
==============
*/

- (IBAction)formTarget: sender
{
	int			i;
	worldthing_t	*thing;
	
	basething.angle = [fields_i intValueAt: 0];
	basething.type = [fields_i intValueAt: 1];
	basething.options = [ambush_i	intValue]<<3;
	basething.options |= ([network_i	intValue]&1)<<4;
	basething.options |= [[difficulty_i cellAtRow:0 column:0] intValue]&1;
	basething.options |= ([[difficulty_i cellAtRow:1 column:0] intValue]&1)<<1;
	basething.options |= ([[difficulty_i cellAtRow:2 column:0] intValue]&1)<<2;
	
	thing = &things[0];
	for (i=0 ; i<numthings ; i++, thing++)
		if (thing->selected > 0)
		{
			thing->angle = basething.angle;
			thing->type = basething.type;
			thing->options = basething.options;
			[editworld_i changeThing: i to: thing];
			[doomproject_i	setMapDirty:TRUE];
		}
}


/*
==============
=
= updateThingInspector
=
==============
*/

- updateThingInspector
{
	int			i;
	worldthing_t	*thing;
	
	thing = &things[0];
	for (i=0 ; i<numthings ; i++, thing++)
		if (thing->selected > 0)
		{
			basething = *thing;
			break;
		}
		
	if (bcmp (&basething, &oldthing, sizeof(basething)) )
	{
		memcpy (&oldthing, &basething, sizeof(oldthing));
		[self updateInspector: NO];
	}
			
	return self;
}	


/*
===================
=
= windowDidUpdate:
=
===================
*/

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa would call this method at every event)
- windowDidUpdate:sender
{
	[self updateInspector: YES];
		
	return self;
}
#endif


@end
