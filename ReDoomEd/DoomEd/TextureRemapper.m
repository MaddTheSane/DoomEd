// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"EditWorld.h"
#import	"TexturePalette.h"
#import	"TextureRemapper.h"

id	textureRemapper_i;

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

- (void)addToList:(char *)orgname to:(char *)newname;
{
	[remapper_i	addToList:orgname to:newname];
}

//===================================================================
//
//	Delegate methods
//
//===================================================================
- (const char *)getOriginalName
{
	return [texturePalette_i	getSelTextureName];
}

- (const char *)getNewName
{
	return [texturePalette_i	getSelTextureName];
}

- (int)doRemap:(char *)oldname to:(char *)newname
{
	int		i;
	int		linenum;
	int		flag;
	
#ifdef REDOOMED
	// prevent buffer overflows: before calling strcpy(), clip the source string to
	// the destination strings' (worldside_t's top/bottom/midtexture) buffer size
	macroRDE_ClipCStringLocallyForBufferSize(newname,
	                                        macroRDE_SizeOfTypeMember(worldside_t, toptexture));
#endif

	linenum = 0;
	for (i = 0;i < numlines; i++)
	{
		flag = 0;
		// SIDE 0
		if (!strcasecmp ( oldname,lines[i].side[0].bottomtexture))
		{
			strcpy(lines[i].side[0].bottomtexture, newname );
			flag++;
		}
		if (!strcasecmp( oldname,lines[i].side[0].midtexture))
		{
			strcpy(lines[i].side[0].midtexture, newname );
			flag++;
		}
		if (!strcasecmp( oldname ,lines[i].side[0].toptexture))
		{
			strcpy(lines[i].side[0].toptexture, newname );
			flag++;
		}

		// SIDE 1
		if (!strcasecmp ( oldname,lines[i].side[1].bottomtexture))
		{
			strcpy(lines[i].side[1].bottomtexture, newname );
			flag++;
		}
		if (!strcasecmp( oldname,lines[i].side[1].midtexture))
		{
			strcpy(lines[i].side[1].midtexture, newname );
			flag++;
		}
		if (!strcasecmp( oldname ,lines[i].side[1].toptexture))
		{
			strcpy(lines[i].side[1].toptexture, newname );
			flag++;
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
