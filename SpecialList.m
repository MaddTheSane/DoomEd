#import "SpecialList.h"
#import "DoomProject.h"
#import "SpecialListWindow.h"

@implementation SpecialList
@synthesize delegate;
//=====================================================================
//
//	Special List
//
//=====================================================================
- init
{
	if (self = [super init]) {
	delegate = NULL;
	frameString = nil;
	}
	return self;
}

- (void)dealloc
{
	[frameString release];
	[title release];
	
	[super dealloc];
}

- (CompatibleStorage *) getSpecialList
{
	return specialList_i;
}

- (void)empty
{
	[specialList_i	empty];
}

- (void)saveFrame
{
	if (frameString != nil)
		[specialPanel_i	saveFrameUsingName:frameString];
}

@synthesize frameName=frameString;
@synthesize specialTitle=title;

//===================================================================
//
//	Load the .nib (if needed) and display the panel
//
//===================================================================
- (void)displayPanel
{
	if (!specialPanel_i)
	{
		[[NSBundle mainBundle] loadNibNamed: @"SpecialList"
									  owner: self
							topLevelObjects:nil];
		[specialPanel_i	setTitle:title];
		if (frameString != nil)
			[specialPanel_i	setFrameUsingName:frameString];
		[specialPanel_i	setParent:self];
	}
	[specialBrowser_i	reloadColumn:0];
	[specialPanel_i	makeKeyAndOrderFront:NULL];
}

//===================================================================
//
//	Scroll the browser to the specified item
//
//===================================================================
- (void)scrollToItem:(int)i
{
	id	matrix;
	
	[specialBrowser_i	reloadColumn:0];
	matrix = [specialBrowser_i	matrixInColumn:0];
	[matrix	selectCellAtRow:i column:0];
	[matrix	scrollCellToVisibleAtRow:i column:0];
}
			
//===================================================================
//
//	Suggest a new value for the list
//
//===================================================================
- (IBAction)suggestValue:sender
{
	int	max,i,num,found;
	
	max = [specialList_i	count];
	for (num=1;num<10000;num++)
	{
		found = 0;
		for (i=0;i<max;i++)
			if (((speciallist_t *)[specialList_i	elementAt:i])->value == num)
				found = 1;
		if (!found)
		{
			[specialValue_i	setIntValue:num];
			break;
		}
	}
}

//===================================================================
//
//	Make sure the string isn't weird
//
//===================================================================
- (IBAction)validateSpecialString:sender
{
	int	i;
	char		s[32];
	
	strncpy(s,[specialDesc_i	stringValue].UTF8String,32);
	s[31] = 0;
	for (i=0;i<strlen(s);i++)
	{
		if (s[i]=='\n')
		{
			s[i] = 0;
			break;
		}
	
		if (s[i]==' ')
			s[i]='_';
	}
	
	[specialDesc_i	setStringValue:@(s)];
}

//===================================================================
//
//	Fill data from textfields
//
//===================================================================
- (void)fillSpecialData:(speciallist_t *)special
{
	special->value = [specialValue_i	intValue];
	[self	validateSpecialString:NULL];
	strcpy(special->desc,[specialDesc_i	stringValue].UTF8String);
}

//===================================================================
//
//	Take data in textfields and add that data to the list
//
//===================================================================
- (IBAction)addSpecial:sender
{
	speciallist_t		t;
	int	which;
	id	matrix;

	[self	fillSpecialData:&t];
	
	//
	// check for duplicate name
	//
	if ([self	findSpecial:t.value] >= 0)
	{
		NSBeep();
		NSRunAlertPanel(@"Oops!",
			@"You already have a LINE SPECIAL by that name!",
			@"OK", nil, nil, nil);
		return;
	}

	[specialList_i	addElement:&t];
	[specialBrowser_i	reloadColumn:0];
	which = [self	findSpecial:t.value];
	matrix = [specialBrowser_i	matrixInColumn:0];
	[matrix	selectCellAtRow:which column:0];
	[matrix	scrollCellToVisibleAtRow:which column:0];
	[doomproject_i	setProjectDirty:TRUE];
}

//===================================================================
//
//	Based on a string, find the value that represents it
//
//===================================================================
- (int)findSpecialString:(char *)string
{
	int	max, i;
	speciallist_t		*t;
	
	max = [specialList_i	count];
	for (i = 0;i < max; i++)
	{
		t = [specialList_i	elementAt:i];
		if (!strcmp(string,t->desc))
			return i;
	}
	return -1;
}

//===================================================================
//
//	Fill textfields from data
//
//===================================================================
- (void)fillDataFromSpecial:(speciallist_t *)special
{
	[specialValue_i	setIntValue:special->value];
	[specialDesc_i	setStringValue:@(special->desc)];
}

//===================================================================
//
//	Clicked on browser entry.  Tell delegate which value was selected.
//
//===================================================================
- (IBAction)chooseSpecial:sender
{
	id	cell;
	int	which;
	speciallist_t		*t;
	
	cell = [sender	selectedCell];
	if (!cell)
		return;
		
	which = [self	findSpecialString:(char *)[cell  stringValue]];
	if (which < 0)
	{
		NSBeep();
		printf("Whoa! Can't find that special!\n");
		return;
	}

	t = [specialList_i	elementAt:which];
	[self	fillDataFromSpecial:t];
	[delegate specialChosen:t->value];
}

//===================================================================
//
//	Highlight special with matching value and fill textfields with the data
//
//===================================================================
- (void)setSpecial:(int)which
{
	int	i,max;
	speciallist_t	*s;
	id	matrix;
	
	max = [specialList_i	count];
	matrix = [specialBrowser_i	matrixInColumn:0];
	for (i=0;i<max;i++)
	{
		s = [specialList_i	elementAt:i];
		if (s->value == which)
		{
			[matrix	selectCellAtRow:i column:0];
			[matrix	scrollCellToVisibleAtRow:i column:0];
			[self	fillDataFromSpecial:s];
			return;
		}
	}
	[specialDesc_i	setStringValue:@""];
	[specialValue_i	setStringValue:@""];
}

//===================================================================
//
//	Sort the specials list alphabetically
//
//===================================================================
- (void)sortSpecials
{
	id	cell, matrix;
	int	max,i,j,flag, which;
	speciallist_t		*t1, *t2, tt1, tt2;
	char		name[32] = "\0";
	
	cell = [specialBrowser_i	selectedCell];
	if (cell)
		strcpy(name,[cell	stringValue].UTF8String);
	max = [specialList_i	count];
	
	do
	{
		flag = 0;
		for (i = 0;i < max; i++)
		{
			t1 = [specialList_i	elementAt:i];
			for (j = i + 1;j < max;j++)
			{
				t2 = [specialList_i	elementAt:j];
				if (strcasecmp(t2->desc,t1->desc) < 0)
				{
					tt1 = *t1;
					tt2 = *t2;
					[specialList_i	replaceElementAt:j  with:&tt1];
					[specialList_i	replaceElementAt:i  with:&tt2];
					flag = 1;
					break;
				}
			}
		}
	} while(flag);
	
	which = [self	findSpecialString:name];
	if (which >= 0)
	{
		matrix = [specialBrowser_i	matrixInColumn:0];
		[matrix	selectCellAtRow:which column:0];
		[matrix	scrollCellToVisibleAtRow:which column:0];
	}
}

//===================================================================
//
//	Delegate method called by "specialBrowser_i" when reloadColumn is invoked
//
//===================================================================
- (void)browser:(NSBrowser *)sender createRowsForColumn:(NSInteger)column inMatrix:(NSMatrix *)matrix
{
	NSInteger	max, i;
	NSBrowserCell	*cell;
	speciallist_t		*t;
	
	if (column > 0)
		return;
		
	[self	sortSpecials];
	max = [specialList_i	count];
	for (i = 0; i < max; i++)
	{
		t = [specialList_i	elementAt:i];
		[matrix	insertRow:i];
		cell = [matrix	cellAtRow:i	column:0];
		[cell	setStringValue:@(t->desc)];
		[cell setLeaf: YES];
		[cell setLoaded: YES];
		[cell setEnabled: YES];
	}
	//return max;
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column
{
	
}

//============================================================
//
// Handling .DSP file
//
//============================================================
- (BOOL) readSpecial:(speciallist_t *)special	from:(FILE *)stream
{
	if (fscanf(stream,"%d:%s\n",&special->value,special->desc) != 2)
		return NO;
	return YES;
}

- writeSpecial:(speciallist_t *)special	from:(FILE *)stream
{
	fprintf(stream,"%d:%s\n",special->value,special->desc);
	return self;
}

//
// return index of special in masterList. value is used for search thru list.
//
- (int)findSpecial:(int)value
{
	int	max, i;
	speciallist_t		*t;
	
	max = [specialList_i	count];
	for (i = 0;i < max; i++)
	{
		t = [specialList_i	elementAt:i];
		if (value == t->value)
			return i;
	}
	return -1;
}

- (void)updateSpecialsDSP:(FILE *)stream
{
	speciallist_t		t,*t2;
	int	count, i, found;
	
	//
	// read specials out of the file, only adding new specials to the current list
	//
	if (!specialList_i)
		specialList_i = [[CompatibleStorage alloc]
			initCount: 0
			elementSize: sizeof(speciallist_t)
			description: NULL
		];

	if (fscanf (stream, "numspecials: %d\n", &count) == 1)
	{
		for (i = 0; i < count; i++)
		{
			[self	readSpecial:&t	from:stream];
			found = [self	findSpecial:t.value];
			if (found < 0)
			{
				[specialList_i	addElement:&t];
				[doomproject_i	setProjectDirty:TRUE];
			}
		}
		[specialBrowser_i	reloadColumn:0];

		//
		// now, write out the new file!
		//
		count = [specialList_i	count];
		fseek (stream, 0, SEEK_SET);
		fprintf (stream, "numspecials: %d\n",count);
		for (i = 0; i < count; i++)
		{
			t2 = [specialList_i	elementAt:i];
			[self	writeSpecial:t2	from:stream];
		}
	}
	else
		fprintf(stream,"numspecials: %d\n",0);
}


@end
