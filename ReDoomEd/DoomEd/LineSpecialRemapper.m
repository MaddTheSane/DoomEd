// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"LinePanel.h"
#import "LineSpecialRemapper.h"
#import	"SpecialList.h"

id	lineSpecialRemapper_i;

@implementation LineSpecialRemapper

//===================================================================
//
//	REMAP Line Specials IN MAP
//
//===================================================================
- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	lineSpecialRemapper_i = self;
	
	remapper_i = [[Remapper alloc] init];
	[remapper_i setFrameName:@"LineSpecialRemapper"
				  panelTitle:@"Line Special Remapper"
				browserTitle:@"List of line specials to be remapped"
				 remapString:@"Special"
					delegate:self];
	return self;
}

//===================================================================
//
//	Bring up panel
//
//===================================================================
- (IBAction)menuTarget:sender
{
	[remapper_i	showPanel];
}

- (void)addToList:(char *)orgname to:(char *)newname;
{
	[remapper_i	addToList:orgname to:newname];
}

//===================================================================
//
//	Delegate methods
//
//===================================================================
- (NSString *)originalName
{
	speciallist_t	special;

	[lineSpecialPanel_i fillSpecialData:&special];
	return [NSString stringWithFormat:@"%d:%s", special.value, special.desc];
}

- (NSString *)newName
{
	return [self originalName];
}

- (int)doRemapFromName:(NSString *)oldname toName:(NSString *)newname
{
	return [self doRemap:oldname.UTF8String to:newname.UTF8String];
}

- (int)doRemap:(char *)oldname to:(char *)newname
{
	int		i;
	int		linenum;
	int		flag;
	char	string[80];
	int		oldval;
	int		newval;
	
#ifdef REDOOMED
	// prevent buffer overflows: specify string buffer sizes in *scanf() format strings
	sscanf(oldname,"%d:%79s",&oldval,string);
	sscanf(newname,"%d:%79s",&newval,string);
#else // Original
	sscanf(oldname,"%d:%s",&oldval,string);
	sscanf(newname,"%d:%s",&newval,string);
#endif
	
	linenum = 0;
	for (i = 0;i < numlines; i++)
	{
		flag = 0;
		
		if (lines[i].special == oldval)
		{
			lines[i].special = newval;
			flag++;
		}
		
		if (flag)
		{
			printf("Remapped Line Special %s to %s.\n",oldname,newname);
			linenum++;
		}
	}
	
	return linenum;
}

- (void)finishUp
{
}


@end
