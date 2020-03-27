// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "SpecialList.h"
#import "DoomProject.h"

#ifdef REDOOMED
#   import "SpecialListWindow.h"
#endif


@implementation SpecialList

//=====================================================================
//
//	Special List
//
//=====================================================================
- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	delegate = NULL;
	self.frameName = @"";
	return self;
}

- (void)dealloc
{
	[specialList_i release];
	[frameString release];
	[super dealloc];
}

@synthesize specialList=specialList_i;

- (void)empty
{
	[specialList_i	empty];
}

- (void)saveFrame
{
	if (frameString.length != 0)
#ifdef REDOOMED
		[specialPanel_i	saveFrameUsingName:frameString];
#else // Original
		[specialPanel_i	saveFrameUsingName:frameString];
#endif
}

@synthesize frameName=frameString;

- (void)setSpecialTitle:(char *)string
{
	strncpy(title,string,31);
}

@synthesize delegate;

//===================================================================
//
//	Load the .nib (if needed) and display the panel
//
//===================================================================
- (void)displayPanel
{
	if (!specialPanel_i)
	{
		[NXApp 
			loadNibSection:	"SpecialList.nib"
			owner:			self
			withNames:		NO
		];

#ifdef REDOOMED
		[specialPanel_i	setTitle:RDE_NSStringFromCString(title)];
		if (frameString.length != 0)
			[specialPanel_i	setFrameUsingName:frameString];
		[specialPanel_i setParent:self];
#else // Original
		[specialPanel_i	setTitle:title];
		if (frameString[0])
			[specialPanel_i	setFrameUsingName:frameString];
		[specialPanel_i	setParent:self];
#endif
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
	NSMatrix *matrix;
	
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
	NSInteger	max,i,num;
	
	max = [specialList_i	count];
	for (num=1;num<10000;num++)
	{
		BOOL found = NO;
		for (i=0;i<max;i++) {
			if (((speciallist_t *)[specialList_i	elementAt:i])->value == num) {
				found = YES;
			}
		}
		if (!found)
		{
			[specialValue_i	setIntegerValue:num];
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
	
#ifdef REDOOMED
	strncpy(s,(char *)RDE_CStringFromNSString([specialDesc_i stringValue]),32);
#else // Original	
	strncpy(s,(char *)[specialDesc_i	stringValue],32);
#endif

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
	
#ifdef REDOOMED
	[specialDesc_i	setStringValue:RDE_NSStringFromCString(s)];
#else // Original
	[specialDesc_i	setStringValue:s];
#endif
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

#ifdef REDOOMED
	// prevent buffer overflows: strcpy() -> macroRDE_SafeCStringCopy()
	macroRDE_SafeCStringCopy(special->desc,
	                            RDE_CStringFromNSString([specialDesc_i stringValue]));
#else // Original
	strcpy(special->desc,[specialDesc_i	stringValue]);
#endif
}

//===================================================================
//
//	Take data in textfields and add that data to the list
//
//===================================================================
- (IBAction)addSpecial:sender
{
	speciallist_t		t;
	NSInteger	which;
	NSMatrix *matrix;

	[self	fillSpecialData:&t];
	
	//
	// check for duplicate name
	//
	if ([self	findSpecial:t.value] != NSNotFound)
	{
		NSBeep();
		NSRunAlertPanel(NSLocalizedString(@"Oops!", @"Oops!"),
					@"You already have a LINE SPECIAL by that "
					"name!",NSLocalizedString(@"OK", @"OK"),NULL,NULL,NULL);
		return;
	}
	
	[specialList_i	addElement:&t];
	[specialBrowser_i	reloadColumn:0];
	which = [self	findSpecial:t.value];
	matrix = [specialBrowser_i	matrixInColumn:0];
	[matrix	selectCellAtRow:which column:0];
	[matrix	scrollCellToVisibleAtRow:which column:0];
	[doomproject_i setProjectDirty:TRUE];
}

//===================================================================
//
//	Based on a string, find the value that represents it
//
//===================================================================
- (NSInteger)findSpecialString:(const char *)string
{
	NSInteger	max, i;
	speciallist_t		*t;
	
	max = [specialList_i	count];
	for (i = 0;i < max; i++)
	{
		t = [specialList_i	elementAt:i];
		if (!strcmp(string,t->desc))
			return i;
	}
	return NSNotFound;
}

//===================================================================
//
//	Fill textfields from data
//
//===================================================================
- fillDataFromSpecial:(speciallist_t *)special
{
	[specialValue_i	setIntValue:special->value];

#ifdef REDOOMED
	[specialDesc_i	setStringValue:RDE_NSStringFromCString(special->desc)];
#else // Original
	[specialDesc_i	setStringValue:special->desc];
#endif

	return self;
}

//===================================================================
//
//	Clicked on browser entry.  Tell delegate which value was selected.
//
//===================================================================
- (IBAction)chooseSpecial:sender
{
	id	cell;
	NSInteger	which;
	speciallist_t		*t;
	
	cell = [sender	selectedCell];
	if (!cell)
		return;
		
#ifdef REDOOMED
	which = [self	findSpecialString:(char *)RDE_CStringFromNSString([cell stringValue])];
#else // Original
	which = [self	findSpecialString:(char *)[cell  stringValue]];
#endif

	if (which == NSNotFound)
	{
		NSBeep();
		printf("Whoa! Can't find that special!\n");
		return;
	}

	t = [specialList_i	elementAt:which];
	[self	fillDataFromSpecial:t];
	[delegate		specialChosen:t->value];
}

//===================================================================
//
//	Highlight special with matching value and fill textfields with the data
//
//===================================================================
- (void)setSpecial:(int)which
{
	NSInteger	i,max;
	speciallist_t	*s;
	NSMatrix	*matrix;
	
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

#ifdef REDOOMED
	[specialDesc_i	setStringValue:@""];
	[specialValue_i	setStringValue:@""];
#else // Original
	[specialDesc_i	setStringValue:NULL];
	[specialValue_i	setStringValue:NULL];
#endif
}

//===================================================================
//
//	Sort the specials list alphabetically
//
//===================================================================
- (void)sortSpecials
{
	id	cell;
	NSMatrix *matrix;
	NSInteger	max,i,j, which;
	BOOL flag;
	speciallist_t		*t1, *t2, tt1, tt2;
	char		name[32] = "\0";
	
	cell = [specialBrowser_i	selectedCell];
	if (cell)
#ifdef REDOOMED
		// prevent buffer overflows: strcpy() -> macroRDE_SafeCStringCopy()
		macroRDE_SafeCStringCopy(name, RDE_CStringFromNSString([cell stringValue]));
#else // Original
		strcpy(name,[cell	stringValue]);
#endif

	max = [specialList_i	count];
	
	do
	{
		flag = NO;
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
					flag = YES;
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
// Cocoa version
- (void) browser: (NSBrowser *) sender
        createRowsForColumn: (NSInteger) column
        inMatrix: (NSMatrix *) matrix
{
	NSInteger	max, i;
	id	cell;
	speciallist_t		*t;
	
	if (column > 0)
		return; // Cocoa version doesn't return a value
		
	[self	sortSpecials];
	max = [specialList_i	count];
	for (i = 0; i < max; i++)
	{
		t = [specialList_i	elementAt:i];
		[matrix	insertRow:i];
		cell = [matrix cellAtRow:i column:0];

		[cell	setStringValue:RDE_NSStringFromCString(t->desc)];

		[cell setLeaf: YES];
		[cell setLoaded: YES];
		[cell setEnabled: YES];
	}
}

//============================================================
//
// Handling .DSP file
//
//============================================================
- (BOOL) readSpecial:(speciallist_t *)special	from:(FILE *)stream
{
#ifdef REDOOMED
	// prevent buffer overflows: specify string buffer sizes in *scanf() format strings
	if (fscanf(stream,"%d:%31s\n",&special->value,special->desc) != 2)
#else // Original
	if (fscanf(stream,"%d:%s\n",&special->value,special->desc) != 2)
#endif
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
- (NSInteger)findSpecial:(int)value
{
	NSInteger	max, i;
	speciallist_t		*t;
	
	max = [specialList_i	count];
	for (i = 0;i < max; i++)
	{
		t = [specialList_i	elementAt:i];
		if (value == t->value)
			return i;
	}
	return NSNotFound;
}

- (void)updateSpecialsDSP:(FILE *)stream
{
	speciallist_t		t,*t2;
	NSInteger	count, i, found;
	
	//
	// read specials out of the file, only adding new specials to the current list
	//
	if (!specialList_i)
		specialList_i = [[Storage	alloc]
					initCount:		0
					elementSize:	sizeof(speciallist_t)
					description:	NULL];

	int tmpInt;
	if (fscanf (stream, "numspecials: %d\n", &tmpInt) == 1)
	{
		count = tmpInt;
		for (i = 0; i < count; i++)
		{
			[self	readSpecial:&t	from:stream];
			found = [self	findSpecial:t.value];
			if (found != NSNotFound)
			{
				[specialList_i	addElement:&t];
				[doomproject_i	setProjectDirty:YES];
			}
		}
		[specialBrowser_i	reloadColumn:0];

		//
		// now, write out the new file!
		//
		count = [specialList_i	count];
		fseek (stream, 0, SEEK_SET);
		fprintf (stream, "numspecials: %ld\n",(long)count);
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
