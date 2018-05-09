#import	"EditWorld.h"
#import	"TexturePalette.h"
#import	"TextureRemapper.h"

TextureRemapper *textureRemapper_i;

@implementation TextureRemapper

//===================================================================
//
//	REMAP TEXTURES IN MAP
//
//===================================================================
- init
{
	if (self = [super init]) {
	textureRemapper_i = self;

	[self
		setFrameName: @"TextureRemapper"
		setPanelTitle: @"Texture Remapper"
		setBrowserTitle: @"List of textures to be remapped"
		setRemapString: @"Texture"
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
- (IBAction)menuTarget:sender
{
	[self	showPanel];
}

- (void)addToList: (NSString *) orgname to: (NSString *) newname;
{
	[super addToList:orgname to:newname];
}

//===================================================================
//
//	Delegate methods
//
//===================================================================
- (NSString *) getOriginalName
{
	return [NSString stringWithUTF8String:
		[texturePalette_i getSelTextureName]];
}

- (NSString *) getNewName
{
	return [self getOriginalName];
}

- (NSInteger)doRemap: (NSString *) oldn to: (NSString *) newn
{
	const char *oldname, *newname;
	int i;
	int linenum;
	BOOL flag;

	oldname = [oldn UTF8String];
	newname = [newn UTF8String];

	linenum = 0;
	for (i = 0;i < numlines; i++)
	{
		flag = NO;
		// SIDE 0
		if (!strcasecmp ( oldname,lines[i].side[0].bottomtexture))
		{
			strcpy(lines[i].side[0].bottomtexture, newname );
			flag = YES;
		}
		if (!strcasecmp( oldname,lines[i].side[0].midtexture))
		{
			strcpy(lines[i].side[0].midtexture, newname );
			flag = YES;
		}
		if (!strcasecmp( oldname ,lines[i].side[0].toptexture))
		{
			strcpy(lines[i].side[0].toptexture, newname );
			flag = YES;
		}

		// SIDE 1
		if (!strcasecmp ( oldname,lines[i].side[1].bottomtexture))
		{
			strcpy(lines[i].side[1].bottomtexture, newname );
			flag = YES;
		}
		if (!strcasecmp( oldname,lines[i].side[1].midtexture))
		{
			strcpy(lines[i].side[1].midtexture, newname );
			flag = YES;
		}
		if (!strcasecmp( oldname ,lines[i].side[1].toptexture))
		{
			strcpy(lines[i].side[1].toptexture, newname );
			flag = YES;
		}

		if (flag)
		{
			printf("Remapped texture %s to %s.\n",oldname,newname);
			linenum++;
		}
	}

	return linenum;
}

- (void)finishUp
{
}

@end
