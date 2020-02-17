// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

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
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	textureRemapper_i = self;
	
	remapper_i = [[Remapper alloc] init];
	[remapper_i setFrameName:@"TextureRemapper"
				  panelTitle:@"Texture Remapper"
				browserTitle:@"List of textures to be remapped"
				 remapString:@"Texture"
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

- (void)addToListFromName:(NSString *)orgname toName:(NSString *)newname;
{
	[remapper_i addToListFromName:orgname toName:newname];
}


//===================================================================
//
//	Delegate methods
//
//===================================================================
- (NSString *)originalName
{
	const char *orig = [texturePalette_i	getSelTextureName];
	if (!orig) {
		return nil;
	}
	return @(orig);
}

- (NSString *)newName
{
	const char *orig = [texturePalette_i	getSelTextureName];
	if (!orig) {
		return nil;
	}
	return @(orig);
}

- (int)doRemapFromName:(NSString *)oldname toName:(NSString *)newname
{
	int		i;
	int		linenum;
	int		flag;
	const char *oldStr = oldname.UTF8String;
	const char *newStr = newname.UTF8String;

	linenum = 0;
	for (i = 0;i < numlines; i++)
	{
		flag = 0;
		// SIDE 0
		if (!strncasecmp(oldStr, lines[i].side[0].bottomtexture, sizeof(lines[i].side[0].bottomtexture)))
		{
			strncpy(lines[i].side[0].bottomtexture, newStr, sizeof(lines[i].side[0].bottomtexture));
			flag++;
		}
		if (!strncasecmp(oldStr, lines[i].side[0].midtexture, sizeof(lines[i].side[0].midtexture)))
		{
			strncpy(lines[i].side[0].midtexture, newStr, sizeof(lines[i].side[0].midtexture));
			flag++;
		}
		if (!strncasecmp(oldStr, lines[i].side[0].toptexture, sizeof(lines[i].side[0].toptexture)))
		{
			strncpy(lines[i].side[0].toptexture, newStr, sizeof(lines[i].side[0].toptexture));
			flag++;
		}

		// SIDE 1
		if (!strncasecmp(oldStr, lines[i].side[1].bottomtexture, sizeof(lines[i].side[1].bottomtexture)))
		{
			strncpy(lines[i].side[1].bottomtexture, newStr, sizeof(lines[i].side[1].bottomtexture));
			flag++;
		}
		if (!strncasecmp(oldStr, lines[i].side[1].midtexture, sizeof(lines[i].side[1].midtexture)))
		{
			strncpy(lines[i].side[1].midtexture, newStr, sizeof(lines[i].side[1].midtexture));
			flag++;
		}
		if (!strncasecmp(oldStr, lines[i].side[1].toptexture, sizeof(lines[i].side[1].toptexture)))
		{
			strncpy(lines[i].side[1].toptexture, newStr, sizeof(lines[i].side[1].toptexture));
			flag++;
		}
		
		if (flag)
		{
			printf("Remapped texture %s to %s.\n", oldStr, newStr);
			linenum++;
		}
	}
	
	return linenum;
}

- (void)finishUp
{
}

@end
