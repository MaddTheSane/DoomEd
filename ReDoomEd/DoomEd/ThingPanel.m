// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "PreferencePanel.h"
#import "MapWindow.h"
#import "EditWorld.h"
#import "ThingPanel.h"
#import	"ThingPalette.h"
#import	"ThingWindow.h"
#import	"TextureEdit.h"		// for strupr()
#import "ReDoomEd-Swift.h"

@implementation ThingPanelListObject

- (instancetype)init
{
	self = [super init];
	if (self) {
		self.name = @"";
		self.iconName = @"NOICON";
		self.color = NSColor.blackColor;
	}
	return self;
}

- (void)dealloc
{
	[_name release];
	[_iconName release];
	[_color release];
	
	[super dealloc];
}

@end

ThingPanel *thingpanel_i;

@implementation ThingPanel {
	NSMutableArray<ThingPanelListObject*> *masterList_i;
}

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
	masterList_i = [[NSMutableArray alloc] init];
			
	diffDisplay = DIFF_ALL;
	
#ifdef REDOOMED
	// the initial states of the panel's difficulty checkboxes are copied from the bottom
	// three bits of basething.options; set those 3 bits so the checkboxes will initially
	// be on (checked) instead of off (unchecked)
	basething.options |= 0x7;
#endif

	return self;
}

- (void)emptyThingList
{
	[masterList_i	removeAllObjects];
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
		[window_i setParent:self];
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


- (void)saveFrame
{
	if (window_i)
		[window_i	saveFrameUsingName:THINGNAME];
}

- (void)pgmTarget
{
	if (!window_i)
		[self	menuTarget:NULL];
	else
		[window_i	orderFront:NULL];
}

- (ThingPanelListObject *)currentThingData
{
	ThingPanelListObject *thing = [[ThingPanelListObject alloc] init];
	
	if (!typeField)
	{
		NXBeep();
		[thing release];
		return NULL;
	}
		
	thing.value = [typeField intValue];

	thing.name = nameField_i.stringValue;
	thing.iconName = [iconField_i stringValue];

	return [thing autorelease];
}

@synthesize difficultyDisplay=diffDisplay;

///	Change the difficulty of Things to view
- (IBAction)changeDifficultyDisplay:sender
{
	NSCell			*cell;
	
	//
	//	Handle redrawing Edit windows for diff. change
	//
	cell = [sender selectedCell];
	diffDisplay = (int)[cell tag];
	[editworld_i	redrawWindows];
	[self	countCurrentThings];
}

///	Display # of Things that match currently selected type
- (void)countCurrentThings
{
	NSInteger		max;
	int				j;
	ThingPanelListObject		*t;
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
	t = [self	currentThingData];
	count = 0;
	thing = &things[0];

	for (j = 0;j < numthings; j++,thing++)
		if (t.value == thing->type)
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
- (void)selectThingWithIcon:(NSString *)name
{
	NSInteger		max;
	NSInteger		i;
	ThingPanelListObject		*t;
	NSMatrix		*matrix;
	
	max = [masterList_i	count];
	for (i = 0;i < max; i++)
	{
		t = [masterList_i	objectAtIndex:i];
		if ([name caseInsensitiveCompare:t.iconName] == NSOrderedSame)
		{
			[self	fillDataFromThing:t];
			matrix = [thingBrowser_i	matrixInColumn:0];
			[matrix	selectCellAtRow:i column:0];
			[matrix	scrollCellToVisibleAtRow:i column:0];
			return;
		}
	}
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
	NSInteger		iconnum;
	ThingPaletteIcon	*icon;
	
	iconnum = [thingPalette_i	currentIcon];
	if (iconnum == NSNotFound || iconnum == -1)
	{
		NSBeep();
		return;
	}
	icon = [thingPalette_i	getIcon:iconnum];

	[iconField_i	setStringValue:icon.name];

	[updateButton_i	performClick:self];
}

//===================================================================
//
//	Verify a correct icon name input
//
//===================================================================
- (IBAction)verifyIconName:sender
{
	NSString	*name;
	NSInteger	which;
	
	name = [iconField_i stringValue];
	name = [name uppercaseString];

	which = [thingPalette_i	findIcon:name];
	if (which == NSNotFound)
	{
		NSBeep();

		[iconField_i	setStringValue:@"NOICON"];

		return;
	}

	[iconField_i	setStringValue:name];
}

//===================================================================
//
//	Suggest a new type for a new Thing
//
//===================================================================
- (IBAction)suggestNewType:sender
{
	NSInteger	num,i,found,max;
	
	max = [masterList_i	count];
	for (num = 1;num < 10000;num++)
	{
		found = 0;
		for (i = 0;i < max;i++)
			if (([masterList_i	objectAtIndex:i]).value == num)
			{
				found = 1;
				break;
			}
		if (!found)
		{
			[typeField setIntegerValue:num];
			return;
		}
	}
}

//
// delegate method called by "thingBrowser_i"
//
// Cocoa version
- (void) browser: (NSBrowser *) sender
        createRowsForColumn: (NSInteger) column
        inMatrix: (NSMatrix *) matrix
{
	NSInteger	max, i;
	id	cell;
	ThingPanelListObject		*t;
	
	if (column > 0)
		return; // Cocoa version doesn't return a value
		
	[self	sortThings];
	max = [masterList_i	count];
	for (i = 0; i < max; i++)
	{
		t = [masterList_i	objectAtIndex:i];
		[matrix	insertRow:i];
		cell = [matrix cellAtRow:i column:0];

		[cell	setStringValue:t.name];

		[cell setLeaf: YES];
		[cell setLoaded: YES];
		[cell setEnabled: YES];
	}
}

///
/// sort the thing list
///
- (void)sortThings
{
	id	cell;
	NSMatrix *matrix;
	NSInteger	which;
	NSString	*name = nil;
	
	cell = [thingBrowser_i	selectedCell];
	if (cell)
		name = [cell stringValue];

	[masterList_i sortUsingComparator:^NSComparisonResult(ThingPanelListObject *_Nonnull t1, ThingPanelListObject *_Nonnull t2) {
		return [t2.name caseInsensitiveCompare:t1.name];
	}];
	
	
	which = [self findThing:name];
	if (which != NSNotFound)
	{
		matrix = [thingBrowser_i matrixInColumn:0];
		[matrix	selectCellAtRow:which column:0];
		[matrix	scrollCellToVisibleAtRow:which column:0];
	}			
}

///
/// update current thing with current data
///
- (IBAction)updateThingData:sender
{
	id			cell;
	NSInteger	which;
	ThingPanelListObject	*t;
#ifdef REDOOMED
	NSColor *oldColor, *newColor;
#endif
	
	cell = [thingBrowser_i		selectedCell];
	if (!cell)
	{
		NXBeep();
		return;
	}

#ifdef REDOOMED
	which = [self	findThing:[cell stringValue]];
#else // Original
	which = [self	findThing:(char *)[cell	stringValue]];
#endif

	t = [masterList_i	objectAtIndex:which];

#ifdef REDOOMED
	oldColor = [[t.color retain] autorelease];
#endif

	[self	fillThingData:t];

#ifdef REDOOMED
	newColor = t.color;
#endif

	[thingBrowser_i	reloadColumn:0];
	[[thingBrowser_i	matrixInColumn:0]
	 selectCellAtRow:which == NSNotFound ? -1 : which  column:0];
	[doomproject_i	setProjectDirty:TRUE];

#ifdef REDOOMED
	if (![oldColor isEqual:newColor])
	{
		// thing color changed - refresh the mapviews
		[editworld_i redrawWindows];
	}
#endif
}

///
/// take data from input fields and update thing data
///
- (void)fillThingData:(ThingPanelListObject *)thing
{
	thing.angle = [angleField		intValue];
	thing.value = [typeField		intValue];
	[self	confirmCorrectNameEntry:NULL];

	thing.name = nameField_i.stringValue;

	thing.option = [ambush_i	intValue]<<3;
	thing.option |= ([network_i	intValue]&1)<<4;
	thing.option |= [[difficulty_i cellAtRow:0 column:0] intValue]&1;
	thing.option |= ([[difficulty_i cellAtRow:1 column:0] intValue]&1)<<1;
	thing.option |= ([[difficulty_i cellAtRow:2 column:0] intValue]&1)<<2;

	thing.color = thingColor_i.color;
	thing.iconName = iconField_i.stringValue;

	if (thing.iconName.length == 0) {
		thing.iconName = @"NOICON";
	}
}

///
/// corrects any wrongness in namefield
///
- (IBAction)confirmCorrectNameEntry:sender
{
	char		name[32];
	int	i;

	memset(name, 0, 32);

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

///
/// fill-in the information for a worldthing_t
///
- (void)getThing:(worldthing_t	*)thing
{
	thing->angle = [angleField	intValue];
	thing->type = [typeField	intValue];
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
	NSInteger	which;
	ThingPanelListObject		*t;
	
	which = [self	searchForThingType:thing->type];
	if (which != NSNotFound)
	{
		t = [masterList_i	objectAtIndex:which];
		t.option = thing->options;
		t.angle = thing->angle;
		
		[self	fillAllDataFromThing:t];
		[self	scrollToItem:which];
		[thingPalette_i	setCurrentIcon:[thingPalette_i	findIcon:t.iconName]];
	}
}

@synthesize thingList=masterList_i;

- (void)scrollToItem:(NSInteger)which
{
	NSMatrix *matrix;
	
	matrix = [thingBrowser_i matrixInColumn:0];
	[matrix	selectCellAtRow:which column:0];
	[matrix	scrollCellToVisibleAtRow:which column:0];
}

- (IBAction)setAngle:sender
{
	[angleField setIntegerValue:[[sender selectedCell] tag]];
	[self		formTarget:NULL];
}

- (NSColor*)thingColorForType:(int)type
{
	NSInteger	index;
	
	index = [self  searchForThingType:type];
	if (index == NSNotFound)
		return [prefpanel_i colorForColor: SELECTED_C];
	return	[masterList_i objectAtIndex:index].color;
}

///
/// you know the thing's type, but don't know the name!
///
- (NSInteger)searchForThingType:(int)type
{
	NSInteger	max,i;
	ThingPanelListObject		*t;
	
	max = [masterList_i	count];
	for (i = 0;i < max;i++)
	{
		t = [masterList_i	objectAtIndex:i];
		if (t.value == type)
			return i;
	}
	return NSNotFound;
}

///
/// fill data from thing
///
- (void)fillDataFromThing:(ThingPanelListObject *)thing
{
	[typeField setIntValue:thing.value];

	[nameField_i	setStringValue:thing.name];
	[thingColor_i	setColor:thing.color];
	[iconField_i	setStringValue:thing.iconName];
	
	basething.type = thing.value;
}

///
/// fill ALL data from thing
///
- (void)fillAllDataFromThing:(ThingPanelListObject *)thing
{
	[self	fillDataFromThing:thing];
	
	[angleField	setIntValue:thing.angle];
	[ambush_i	setState:((thing.option)>>3)&1];
	[network_i	setState:((thing.option)>>4)&1];
	[[difficulty_i cellAtRow:0 column:0] setState:(thing.option)&1];
	[[difficulty_i cellAtRow:1 column:0] setState:((thing.option)>>1)&1];
	[[difficulty_i cellAtRow:2 column:0] setState:((thing.option)>>2)&1];
	
	basething.angle = thing.angle;
	basething.options = thing.option;
}

///
/// Add "type" to thing list
///
- (IBAction)addThing:sender
{
	ThingPanelListObject		*t = [[ThingPanelListObject alloc] init];
	NSInteger	which;
	NSMatrix	*matrix;

	[self	fillThingData:t];
	
	//
	// check for duplicate name
	//
	if ([self	findThing:t.name] != NSNotFound)
	{
		NXBeep();
		NSRunAlertPanel(@"Oops!",
			@"You already have a THING by that name!",@"OK",NULL,NULL,NULL);
		[t release];
		return;
	}
	
	[masterList_i	addObject:t];
	[t release];
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

///
/// return index of thing in masterList. "string" is used for search thru list.
///
- (NSInteger)findThing:(NSString *)string
{
	NSInteger	max, i;
	ThingPanelListObject		*t;
	
	max = [masterList_i	count];
	for (i = 0;i < max; i++)
	{
		t = [masterList_i	objectAtIndex:i];
		if ([string caseInsensitiveCompare:t.name] == NSOrderedSame)
			return i;
	}
	return NSNotFound;
}

- (ThingPanelListObject *)getThingData:(NSInteger)index
{
	return [masterList_i	objectAtIndex:index];
}

///
/// user chose an item in the thingBrowser_i.
/// stick the info in the "name" and "type" fields.
//
- (IBAction)chooseThing:sender
{
	id			cell;
	NSInteger	which;
	ThingPanelListObject	*t;
	
	cell = [sender	selectedCell];
	if (!cell)
		return;
		
#ifdef REDOOMED
	which = [self findThing:[cell stringValue]];
#else // Original
	which = [self	findThing:(char *)[cell	stringValue]];
#endif

	if (which == NSNotFound)
	{
		NXBeep();
		printf("Whoa! Can't find that thing!\n");
		return;
	}

	t = [masterList_i	objectAtIndex:which];
	[self	fillDataFromThing:t];
	[self	formTarget:NULL];
	which = [thingPalette_i	findIcon:t.iconName];
	if (which != NSNotFound)
		[thingPalette_i	setCurrentIcon:which];
}

- (BOOL) readThing:(ThingPanelListObject *)thing	from:(FILE *)stream
{
	char tmpName[32];
	char tmpIconName[10];
	int tmpAngle, tmpValue, tmpOption;
	float	r,g,b;
	
	// prevent buffer overflows: specify string buffer sizes in *scanf() format strings
	if (fscanf(stream,"%31s = %d %d %d (%f %f %f) %8s\n",
			tmpName,&tmpAngle,&tmpValue,&tmpOption,
			&r,&g,&b,tmpIconName) != 8)
		return NO;
	thing.color = RDE_NSColorFromNXColor(NXConvertRGBToColor(r,g,b));
	thing.angle = tmpAngle;
	thing.value = tmpValue;
	thing.option = tmpOption;
	thing.name = @(tmpName);
	thing.iconName = @(tmpIconName);
	return YES;
}

- (void)writeThing:(ThingPanelListObject *)thing	from:(FILE *)stream
{
	float	r,g,b;
	
	NXConvertColorToRGB(RDE_NXColorFromNSColor(thing.color),&r,&g,&b);
	fprintf(stream,"%s = %d %d %d (%f %f %f) %s\n", thing.name.UTF8String, thing.angle, thing.value,
			thing.option,r,g,b,thing.iconName.UTF8String);
}

///
/// update the things.dsp file (when project is saved/loaded)
///
- (void)updateThingsDSP:(FILE *)stream
{
	ThingPanelListObject		*t,*t2;
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
			t = [ThingPanelListObject new];
			[self	readThing:t	from:stream];
			found = [self	findThing:t.name];
			if (found == NSNotFound)
			{
				[masterList_i	addObject:t];
				[doomproject_i	setProjectDirty:TRUE];
			}
			[t release];
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
			t2 = [masterList_i	objectAtIndex:i];
			[self	writeThing:t2	from:stream];
		}
	}
	else
		fprintf(stream,"numthings: %d\n",0);
}
	
/// call with force == YES to update into a window while it is off-screen, otherwise
/// no updating is done if not visible
- (void)updateInspector: (BOOL)force
{
	if (!force && ![window_i isVisible])
		return;

	[window_i disableFlushWindow];
	
	[angleField setIntValue: basething.angle];
	[typeField setIntValue: basething.type];
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
}

/// The user has edited something in a form cell
- (IBAction)formTarget: sender
{
	int			i;
	worldthing_t	*thing;
	
	basething.angle = [angleField intValue];
	basething.type = [typeField intValue];
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

- (void)updateThingInspector
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
		
	if (memcmp (&basething, &oldthing, sizeof(basething)) )
	{
		memcpy (&oldthing, &basething, sizeof(oldthing));
		[self updateInspector: NO];
	}
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

-(void)dealloc
{
	[masterList_i release];
	[super dealloc];
}

@end
