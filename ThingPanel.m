#import "PreferencePanel.h"
#import "MapWindow.h"
#import "EditWorld.h"
#import "ThingPanel.h"
#import	"ThingPalette.h"
#import	"ThingWindow.h"
#import	"TextureEdit.h"		// for strupr()

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
	if (self = [super init]) {
	thingpanel_i = self;
	window_i = NULL;		// until nib is loaded
	masterList_i = [[CompatibleStorage alloc]
		initCount: 0
		elementSize: sizeof(thinglist_t)
		description: NULL
	];

	diffDisplay = DIFF_ALL;
	}

	return self;
}

- (void)emptyThingList
{
	[masterList_i	empty];
}

/*
==============
=
= menuTarget:
=
==============
*/

- (void)menuTarget:sender
{
	if (!window_i)
	{
		[[NSBundle mainBundle] loadNibNamed: @"thing"
									  owner: self
							topLevelObjects:nil];
		[window_i	setFrameUsingName:THINGNAME];
		[window_i	setDelegate:self];
		[thingBrowser_i	reloadColumn:0];
		[diffDisplay_i	selectCellAtRow:diffDisplay column:0];
		[count_i	setStringValue:@" "];
		[window_i	setParent:self];
	}

	[window_i makeKeyAndOrderFront:self];
}

- (void)windowDidMiniaturize:(NSNotification *)notification
{
	NSWindow *window = [notification object];
	//[window setMiniwindowIcon:"DoomEd"];
	[window setMiniwindowTitle:@"Things"];
}


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

- (thinglist_t *)getCurrentThingData
{
	thinglist_t		thing;
	
	if (!fields_i)
	{
		NSBeep();
		return NULL;
	}
		
	thing.value = [[fields_i cellAtIndex:1] intValue];
	strcpy(thing.name,[nameField_i stringValue].UTF8String);
	strncpy(thing.iconname,[iconField_i stringValue].UTF8String, sizeof(thing.iconname));

	return &thing;
}

- (BOOL)getCurrentThingData:(thinglist_t *)thing;
{
	if (!thing) {
		return NO;
	}
	
	if (!fields_i)
	{
		NSBeep();
		return NO;
	}
	
	thing->value = [[fields_i cellAtIndex:1] intValue];
	strcpy(thing->name,[nameField_i stringValue].UTF8String);
	strncpy(thing->iconname,[iconField_i stringValue].UTF8String, sizeof(thing->iconname));
	
	return YES;
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
- (void)changeDifficultyDisplay:sender
{
	id				cell;
	
	//
	//	Handle redrawing Edit windows for diff. change
	//
	cell = [sender selectedCell];
	diffDisplay = [cell tag];
	[editworld_i	redrawWindows];
	[self	currentThingCount];
}

//===================================================================
//
//	Display # of Things that match currently selected type
//
//===================================================================
- (void)currentThingCount
{
	NSInteger		max;
	int				j;
	thinglist_t		t;
	worldthing_t	*thing;
	int				count;

	//
	//	Count up how many of currently selected Thing there is
	//
	if (diffDisplay == DIFF_ALL)
	{
		[count_i	setStringValue:@"-"];
		return;
	}
		
	max = [masterList_i	count];
	[self	getCurrentThingData:&t];
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
- (void)selectThingWithIcon:(char *)name
{
	int				max;
	int				i;
	thinglist_t		*t;
	id				matrix;
	
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
			return;
		}
	}
}

//===================================================================
//
//	Unlink icon from this Thing
//
//===================================================================
- (void)unlinkIcon:sender
{
	[iconField_i	setStringValue:@"NOICON"];
	[updateButton_i	performClick:self];
}

//===================================================================
//
//	Assign icon selected in Thing Palette to current thing data
//
//===================================================================
- (void)assignIcon:sender
{
	int		iconnum;
	icon_t	*icon;
	
	iconnum = [thingPalette_i	currentIcon];
	if (iconnum < 0)
	{
		NSBeep();
		return;
	}
	icon = [thingPalette_i	getIcon:iconnum];
	[iconField_i	setStringValue:@(icon->name)];
	[updateButton_i	performClick:self];
}

//===================================================================
//
//	Verify a correct icon name input
//
//===================================================================
- (void)verifyIconName:sender
{
	char	name[10];
	int		which;
	
	strncpy(name,[iconField_i stringValue].UTF8String, sizeof(name));
	strupr(name);
	which = [thingPalette_i	findIcon:name];
	if (which < 0)
	{
		NSBeep();
		[iconField_i	setStringValue:@"NOICON"];
		return;
	}
	[iconField_i	setStringValue:@(name)];
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
			if (((thinglist_t *)[masterList_i	elementAt:i])->value == num)
			{
				found = 1;
				break;
			}
		if (!found)
		{
			[[fields_i cellAtIndex:1] setIntegerValue:num];
			return;
		}
	}
}

//
// delegate method called by "thingBrowser_i"
//
- (void)browser:(NSBrowser *)sender createRowsForColumn:(NSInteger)column inMatrix:(NSMatrix *)matrix
{
	NSInteger		max, i;
	NSBrowserCell	*cell;
	thinglist_t		*t;
	
	if (column > 0)
		return;
		
	[self	sortThings];
	max = [masterList_i	count];
	for (i = 0; i < max; i++)
	{
		t = [masterList_i	elementAt:i];
		[matrix	insertRow:i];
		cell = [matrix	cellAtRow:i	column:0];
		[cell setStringValue:@(t->name)];
		[cell setLeaf: YES];
		[cell setLoaded: YES];
		[cell setEnabled: YES];
	}
	//return max;
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column
{
	
}

//
// sort the thing list
//
- (void)sortThings
{
	id	cell, matrix;
	int	max,i,j,flag, which;
	thinglist_t		*t1, *t2, tt1, tt2;
	NSString		*name = @"";
	
	cell = [thingBrowser_i	selectedCell];
	if (cell)
		name = [cell stringValue];
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
	
	which = [self	findThing:name.UTF8String];
	if (which >= 0)
	{
		matrix = [thingBrowser_i	matrixInColumn:0];
		[matrix	selectCellAtRow:which column:0];
		[matrix	scrollCellToVisibleAtRow:which column:0];
	}
}

//
// update current thing with current data
//
- (IBAction)updateThingData:sender
{
	id	cell;
	int	which;
	thinglist_t		*t;
	
	cell = [thingBrowser_i		selectedCell];
	if (!cell)
	{
		NSBeep();
		return;
	}
	which = [self	findThing:(char *)[cell	stringValue]];
	t = [masterList_i	elementAt:which];
	[self	fillThingData:t];
	[thingBrowser_i	reloadColumn:0];
	[[thingBrowser_i	matrixInColumn:0]
		selectCellAtRow:which column:0];
	[doomproject_i	setProjectDirty:TRUE];
}

//
// take data from input fields and update thing data
//
- (void)fillThingData:(thinglist_t *)thing
{
	thing->angle = [[fields_i cellAtIndex:0] intValue];
	thing->value = [[fields_i cellAtIndex:1] intValue];
	[self	confirmCorrectNameEntry:NULL];
	strncpy(thing->name, [nameField_i stringValue].UTF8String, sizeof(thing->name));
	thing->option = [ambush_i	intValue]<<3;
	thing->option |= ([network_i	intValue]&1)<<4;
	thing->option |= [[difficulty_i cellAtRow:0 column:0] intValue]&1;
	thing->option |= ([[difficulty_i cellAtRow:1 column:0] intValue]&1)<<1;
	thing->option |= ([[difficulty_i cellAtRow:2 column:0] intValue]&1)<<2;
	thing->color = [thingColor_i	color];
	strncpy(thing->iconname,[iconField_i stringValue].UTF8String, sizeof(thing->iconname));
	if (!thing->iconname[0])
		strcpy(thing->iconname,"NOICON");
}

//
// corrects any wrongness in namefield
//
- (IBAction)confirmCorrectNameEntry:sender
{
	NSString		*name = [nameField_i stringValue];

	if (name.length > 31)
		name = [name substringToIndex:31];
	
	name = [name stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	[nameField_i	setStringValue:name];
}

//
// fill-in the information for a worldthing_t
//
- (void)getThing:(worldthing_t	*)thing
{
	thing->angle = [[fields_i cellAtIndex:0] intValue];
	thing->type = [[fields_i cellAtIndex:1] intValue];
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

- (CompatibleStorage*)getThingList
{
	return masterList_i;
}

- (void)scrollToItem:(int)which
{
	NSMatrix	*matrix;
	
	matrix = [thingBrowser_i	matrixInColumn:0];
	[matrix	selectCellAtRow:which column:0];
	[matrix	scrollCellToVisibleAtRow:which column:0];
}

- (IBAction)setAngle:sender
{
	[[fields_i cellAtIndex:0] setIntegerValue:[[sender selectedCell] tag]];
	[self		formTarget:NULL];
}

- (NSColor *)getThingColor:(int)type
{
	int	index;
	
	index = [self  searchForThingType:type];
	if (index < 0)
		return [prefpanel_i colorFor: SELECTED_C];
	return	((thinglist_t *)[masterList_i	elementAt:index])->color;
}

//
// you know the thing's type, but don't know the name!
//
- (int)searchForThingType:(int)type
{
	int	max,i;
	thinglist_t		*t;
	
	max = [masterList_i	count];
	for (i = 0;i < max;i++)
	{
		t = [masterList_i	elementAt:i];
		if (t->value == type)
			return i;
	}
	return -1;
}

//
// fill data from thing
//
- (void)fillDataFromThing:(thinglist_t *)thing
{
	[[fields_i cellAtIndex:1] setIntValue:thing->value];
	[nameField_i	setStringValue:@(thing->name)];
	[thingColor_i	setColor:thing->color];
	[iconField_i	setStringValue:@(thing->iconname)];
	
	basething.type = thing->value;
}

//
// fill ALL data from thing
//
- (void)fillAllDataFromThing:(thinglist_t *)thing
{
	[self	fillDataFromThing:thing];
	
	[[fields_i cellAtIndex:0] setIntValue:thing->angle];
	[ambush_i	setIntValue:((thing->option)>>3)&1];
	[network_i	setIntValue:((thing->option)>>4)&1];
	[[difficulty_i cellAtRow:0 column:0] setIntValue:(thing->option)&1];
	[[difficulty_i cellAtRow:1 column:0] setIntValue:((thing->option)>>1)&1];
	[[difficulty_i cellAtRow:2 column:0] setIntValue:((thing->option)>>2)&1];
	
	basething.angle = thing->angle;
	basething.options = thing->option;
}

//
// Add "type" to thing list
//
- (IBAction)addThing:sender
{
	thinglist_t		t;
	int	which;
	id	matrix;

	[self	fillThingData:&t];
	
	//
	// check for duplicate name
	//
	if ([self	findThing:t.name] >= 0)
	{
		NSBeep();
		NSRunAlertPanel(@"Oops!",
			@"You already have a THING by that name!",
			@"OK", nil, nil, nil);
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
- (int)findThing:(const char *)string
{
	int	max, i;
	thinglist_t		*t;
	
	max = [masterList_i	count];
	for (i = 0;i < max; i++)
	{
		t = [masterList_i	elementAt:i];
		if (!strcasecmp(t->name,string))
			return i;
	}
	return -1;
}

- (thinglist_t *)getThingData:(int)index
{
	return [masterList_i	elementAt:index];		
}

//
// user chose an item in the thingBrowser_i.
// stick the info in the "name" and "type" fields.
//
- (IBAction)chooseThing:sender
{
	id		cell;
	int		which;
	thinglist_t		*t;
	
	cell = [sender	selectedCell];
	if (!cell)
		return;
		
	which = [self	findThing:[cell	stringValue].UTF8String];
	if (which < 0)
	{
		NSBeep();
		printf("Whoa! Can't find that thing!\n");
		return;
	}

	t = [masterList_i	elementAt:which];
	[self	fillDataFromThing:t];
	[self	formTarget:NULL];
	which = [thingPalette_i	findIcon:t->iconname];
	if (which >= 0)
		[thingPalette_i	setCurrentIcon:which];
}

- (BOOL) readThing:(thinglist_t *)thing	from:(FILE *)stream
{
	float	r,g,b;
	
	if (fscanf(stream,"%s = %d %d %d (%f %f %f) %s\n",
			thing->name,&thing->angle,&thing->value,&thing->option,
			&r,&g,&b,thing->iconname) != 8)
		return NO;
	thing->color = [NSColor colorWithRed:r green:g blue:b alpha:1.0];
	return YES;
}

- (void)writeThing:(thinglist_t *)thing	from:(FILE *)stream
{
	CGFloat	r,g,b;
	
	[[thing->color colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:NULL];
	fprintf(stream,"%s = %d %d %d (%f %f %f) %s\n",thing->name,thing->angle,thing->value,
			thing->option,r,g,b,thing->iconname);
}

//
// update the things.dsp file (when project is saved/loaded)
//
- (void)updateThingsDSP:(FILE *)stream
{
	thinglist_t		t,*t2;
	int	count, i, found;
	
	//
	// read things out of the file, only adding new things to the current list
	//
	if (fscanf (stream, "numthings: %d\n", &count) == 1)
	{
		for (i = 0; i < count; i++)
		{
			[self	readThing:&t	from:stream];
			found = [self	findThing:t.name];
			if (found < 0)
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
		fprintf (stream, "numthings: %d\n",count);
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

- (void)updateInspector: (BOOL)force
{
	if (!force && ![window_i isVisible])
		return;

	[window_i disableFlushWindow];
	
	[[fields_i cellAtIndex:0] setIntValue:basething.angle];
	[[fields_i cellAtIndex:1] setIntValue:basething.type];
	[ambush_i	setIntValue:((basething.options)>>3)&1];
	[network_i	setIntValue:((basething.options)>>4)&1];
	[[difficulty_i	cellAtRow:0 column:0] setIntValue:(basething.options)&1];
	[[difficulty_i	cellAtRow:1 column:0] setIntValue:((basething.options)>>1)&1];
	[[difficulty_i	cellAtRow:2 column:0] setIntValue:((basething.options)>>2)&1];
	
	[window_i enableFlushWindow];
	[window_i flushWindow];
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
	
	basething.angle = [[fields_i cellAtIndex: 0] intValue];
	basething.type = [[fields_i cellAtIndex: 1] intValue];
	basething.options = [ambush_i	intValue]<<3;
	basething.options |= ([network_i	intValue]&1)<<4;
	basething.options |= [[difficulty_i cellAtRow:0 column:0] intValue]&1;
	basething.options |= ([[difficulty_i cellAtRow:1 column:0] intValue]&1)<<1;
	basething.options |= ([[difficulty_i cellAtRow:2 column:0] intValue]&1)<<2;
	
	thing = &things[0];
	for (i=0 ; i<numthings ; i++, thing++) {
		if (thing->selected > 0)
		{
			thing->angle = basething.angle;
			thing->type = basething.type;
			thing->options = basething.options;
			[editworld_i changeThing: i to: thing];
			[doomproject_i	setMapDirty:TRUE];
		}
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
		
	if (bcmp (&basething, &oldthing, sizeof(basething)) )
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

- (void)windowDidUpdate:(NSNotification *)notification
{
	[self updateInspector: YES];
}


@end
