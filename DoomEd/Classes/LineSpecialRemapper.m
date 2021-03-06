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
	if (self = [super init]) {
	lineSpecialRemapper_i = self;

	[self
		setFrameName: @"LineSpecialRemapper"
		setPanelTitle: @"Line Special Remapper"
		setBrowserTitle: @"List of line specials to be remapped"
		setRemapString: @"Special"
		setDelegate: self
	];
	}
	
	return self;
}

//===================================================================
//
//	Bring up panel
//
//===================================================================
- (void)menuTarget:sender
{
	[self	showPanel];
}

//===================================================================
//
//	Delegate methods
//
//===================================================================
- (NSString *) getOriginalName
{
	speciallist_t	special;

	[lineSpecialPanel_i fillSpecialData:&special];
	return [NSString stringWithFormat: @"%d:%s",
	                                   special.value,special.desc];
}

- (NSString *) getNewName
{
	return [self getOriginalName];
}

- (NSInteger)doRemap: (NSString *) oldname to: (NSString *) newname
{
	int i;
	int linenum;
	int flag;
	char string[80];
	int oldval;
	int newval;

	sscanf([oldname UTF8String], "%d:%s", &oldval, string);
	sscanf([newname UTF8String], "%d:%s", &newval, string);

	linenum = 0;
	for (i = 0; i < numlines; i++)
	{
		flag = 0;

		if (lines[i].special == oldval)
		{
			lines[i].special = newval;
			flag++;
		}

		if (flag)
		{
			printf("Remapped Line Special %s to %s.\n",
			       [oldname UTF8String], [newname UTF8String]);
			linenum++;
		}
	}

	return linenum;
}

- (void)finishUp
{
}


@end
