// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "SpecialList.h"
#import "DoomProject.h"
#import "SpecialListWindow.h"
#import	"TextureEdit.h"

@implementation SpecialListWindow

- setParent:(id)p
{
	parent_i = p;
	return self;
}

//===================================================================
//
//	Match keypress to first letter
//
//===================================================================
#ifdef REDOOMED
// Cocoa version
- (void) keyDown:(NSEvent *)event
#else // Original
- keyDown:(NXEvent *)event
#endif
{
	char	key[2];
	char	string2[32];
	int		max;
	int		i;
	speciallist_t	*s;
	id		specialList_i;
	int		found;
	int		size;
	int		tries;
	
#ifdef REDOOMED
	// Cocoa compatibility
	key[0] = (char) [[event characters] characterAtIndex: 0];
#else // Original	
	key[0] = event->data.key.charCode;
#endif

	strcat(string,key);
	strupr(string);
	size = strlen(string);
		
	specialList_i = [parent_i  getSpecialList];
	max = [specialList_i	count];
	tries = 2;
	while(tries)
	{
		found = 0;
		
		for (i = 0;i < max; i++)
		{
			s = [specialList_i	elementAt:i];
			strcpy(string2,s->desc);
			strupr(string2);
				
			if (!strncmp(string,string2,size))
			{
				[parent_i	scrollToItem:i];
				found = 1;
				tries = 0;
				break;
			}
		}
		
		if (!found)
		{
			string[0] = key[0];
			string[1] = 0;
			strupr(string);
			size = 1;
			tries--;
		}
	}

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

@end
