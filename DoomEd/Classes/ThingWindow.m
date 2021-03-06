#import	"ThingPanel.h"
#import "ThingWindow.h"
#import	"TextureEdit.h"

@implementation ThingWindow
@synthesize parent=parent_i;

//===================================================================
//
//	Match keypress to first letter
//
//===================================================================
- (void) keyDown:(NSEvent *)event
{
	char	key[2] = {0};
	char	string2[32];
	NSInteger	max;
	int		i;
	thinglist_t	*t;
	CompatibleStorage *thingList_i;
	int		found;
	size_t	size;
	int		tries;
	
	key[0] = [event keyCode];
	strupr(key);
	strcat(string,key);
	size = strlen(string);
		
	thingList_i = [parent_i  getThingList];
	max = [thingList_i	count];
	tries = 2;
	
	while(tries)
	{
		found = 0;
		
		for (i = 0;i < max; i++)
		{
			t = [thingList_i	elementAt:i];
			strcpy(string2,t->name);
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
}

@end
