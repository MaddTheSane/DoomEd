#include <sys/types.h>
#include <sys/stat.h>

#import "ps_quartz.h"

#import "DoomProject.h"
#import "TextureEdit.h"
#import "TexturePalette.h"
#import "SectorEditor.h"
#import "EditWorld.h"
#import "Wadfile.h"
#import "LinePanel.h"
#import "ThingPanel.h"
#import "R_mapdef.h"
#import	"TextureRemapper.h"
#import	"FlatRemapper.h"
#import	"TextLog.h"
#import "ThingPalette.h"
#import	"ThermoView.h"

DoomProject *doomproject_i;
Wadfile *wadfile_i;
TextLog *log_i;

int	pp_panel;
int	pp_monsters;
int	pp_items;
int	pp_weapons;

int	numtextures;
worldtexture_t		*textures;

char	mapwads[1024];		// map WAD path
char	bspprogram[1024];	// bsp program path
char	bsphost[32];		// bsp host machine

#define BASELISTSIZE	32

@interface DoomProject()
@property (readwrite, copy) NSString *directory;
@property (readwrite, copy) NSString *wadFile;
@end

@implementation DoomProject


/*
=============================================================================

						PROJECT METHODS

=============================================================================
*/


- init
{
	if (self = [super init]) {
	loaded = NO;
	doomproject_i = self;
	window_i = NULL;
	numtextures = 0;
	texturessize = BASELISTSIZE;
	textures = malloc (texturessize*sizeof(worldtexture_t));
	log_i = [[TextLog alloc] initWithTitle: @"DoomEd Error Log"];
	projectdirty = mapdirty = FALSE;
	}
	
	return self;
}

- (void)checkDirtyProject
{
	NSInteger	val;
	
	if ([self	isProjectDirty] == FALSE)
		return;
		
	val = NSRunAlertPanel(@"Important",
		@"Do you wish to save your project before exiting?",
		@"Yes", @"No", nil);
	if (val == NSAlertDefaultReturn)
		[self	saveProject:self];
}

//
//	App is going to terminate:
//
- (void)quit
{
	[editworld_i	closeWorld];
	[self	checkDirtyProject];
}

@synthesize projectDirty=projectdirty;
@synthesize mapDirty=mapdirty;

- (void)setMapDirty:(BOOL)truth
{
	mapdirty = truth;
	[[editworld_i	getMainWindow] setDocumentEdited:truth];
}

- (void)setDirtyProject:(BOOL)truth
{
	self.projectDirty = truth;
}

- (void)setDirtyMap:(BOOL)truth
{
	self.mapDirty = truth;
}

- (BOOL)mapDirty
{
	return self.mapDirty;
}

- (BOOL)projectDirty
{
	return self.projectDirty;
}

- (IBAction)displayLog:sender
{
	[log_i	display:sender];
}

@synthesize loaded;
@synthesize wadFile=wadfile;
@synthesize directory=projectdirectory;

/*
===============
=
= loadPV1File:
=
===============
*/

- (BOOL)loadPV1File: (FILE *)stream
{
	int		i;
	char	wadDir[1024];
	
	if (fscanf (stream, "\nwadfile: %s\n",wadDir) != 1)
		return NO;
	self.wadFile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:wadDir length:strlen(wadDir)];
	
	if (fscanf (stream, "mapwads: %s\n",mapwads) != 1)
		return NO;
	
	if (fscanf (stream, "BSPprogram: %s\n",bspprogram) != 1)
		return NO;
	
	if (fscanf (stream, "BSPhost: %s\n",bsphost) != 1)
		return NO;
	
	if (fscanf(stream,"nummaps: %d\n", &nummaps) != 1)
		return NO;

	for (i=0 ; i<nummaps ; i++)
	{
		char tmpbuf[9];

		if (fscanf(stream,"%9s\n", tmpbuf) != 1)
			return NO;

		mapnames[i] = [[NSString stringWithUTF8String: tmpbuf] retain];
	}

	return YES;
}

/*
===============
=
= savePV1File:
=
===============
*/

- savePV1File: (FILE *)stream
{
	int	i;

	fprintf (stream, "\nwadfile: %s\n",wadfile.fileSystemRepresentation);
	fprintf (stream, "mapwads: %s\n",mapwads);
	fprintf (stream, "BSPprogram: %s\n",bspprogram);
	fprintf (stream, "BSPhost: %s\n",bsphost);
	fprintf (stream,"nummaps: %d\n", nummaps);
		
	for (i=0 ; i<nummaps ; i++)
		fprintf(stream,"%s\n", [mapnames[i] fileSystemRepresentation]);

	return self;
}


/*
===============
=
= menuTarget
=
===============
*/

- (IBAction)menuTarget: sender
{
	if (!loaded)
	{
		NSRunAlertPanel(@"Error", @"No project loaded", nil, nil, nil);
		return;
	}

	if (!window_i)
	{
		[[NSBundle mainBundle] loadNibNamed: @"Project"
									  owner: self
							topLevelObjects: nil];
		[window_i	setFrameUsingName:DOOMNAME];
	}

	[self updatePanel];
	[window_i orderFront:self];
}

- (BOOL)saveFrame
{
	if (window_i)
		[window_i	saveFrameUsingName:DOOMNAME];
	return YES;
}


/*
===============
=
= openProject
=
===============
*/

- (IBAction)openProject: sender
{
	NSOpenPanel *openpanel;
	NSString *filename;

	[self checkDirtyProject];

	openpanel = [NSOpenPanel openPanel];
	[openpanel setAllowedFileTypes: @[@"dpr"]];
	if ([openpanel runModal] != NSFileHandlingPanelOKButton)
		return;

	printf("Purging existing texture patches.\n");
	[ textureEdit_i	dumpAllPatches ];

	printf("Purging existing flats.\n");
	[ sectorEdit_i	dumpAllFlats ];

	filename = [openpanel filename];

	NSError *err = nil;
	if (![self loadProjectAtPath: filename error:&err])
	{
		NSRunAlertPanel(@"Uh oh!", @"Couldn't load your project!",
		                @"OK", nil, nil);

		[ wadfile_i initWithFilePath: wadfile ];
		[ textureEdit_i initPatches ];
		[ sectorEdit_i loadFlats ];
		[ thingPalette_i initIcons];
		[ wadfile_i close ];

		return;
	}
}

/*
===============
=
= newProject
=
===============
*/

- (IBAction)newProject: sender
{
	FILE *stream;
	NSOpenPanel *panel;
	NSString *filename;
	NSString *projpath;
	NSString *texturepath;


	[self checkDirtyProject];
	//
	// get directory for project & files
	//
	panel = [NSOpenPanel openPanel];
	[panel setTitle: @"Project directory"];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	if ([panel runModal] != NSFileHandlingPanelOKButton)
		return;

	filename = [panel filename];
	if (filename == nil || [filename length] == 0)
	{
		NSRunAlertPanel(@"Nope.",
			@"I need a directory for projects to create one.",
			@"OK", nil, nil);
		return;
	}

	projectdirectory = [filename copy];

	//
	// get wadfile
	//
	[panel setTitle: @"Wadfile"];
	[panel setCanChooseDirectories:NO];
	[panel setCanChooseFiles:YES];
	[panel setAllowedFileTypes: @[@"wad"]];
	if ([panel runModal] != NSFileHandlingPanelOKButton)
		return;

	filename = [panel filename];
	if (filename == nil || [filename length] == 0)
	{
		NSRunAlertPanel(@"Nope.", @"I need a WADfile for this project.",
			@"OK", nil, nil);
		return;
	}

	wadfile = [filename copy];

	//
	// create default data: project file
	//
	nummaps = 0;
	numtextures = 0;

	projpath = projectdirectory;
	projpath = [projpath stringByAppendingPathComponent:@"project.dpr"];

	printf("Creating a new project: %s\n", projectdirectory.UTF8String );
	stream = fopen (projpath.fileSystemRepresentation,"w+");
	if (!stream)
	{
		NSRunAlertPanel(@"Error", @"Couldn't create %@.",
			nil, nil, nil, projpath);
		return;
	}
	fprintf (stream, "Doom Project version 1\n\n");
	fprintf (stream, "wadfile: %s\n\n",wadfile.fileSystemRepresentation);
	fprintf (stream,"nummaps: 0\n");
	fclose (stream);

	texturepath = projectdirectory;
	texturepath = [texturepath stringByAppendingPathComponent:@"texture1.dsp"];
	stream = fopen (texturepath.fileSystemRepresentation,"w+");
	if (!stream)
	{
		NSRunAlertPanel(@"Error", @"Couldn't create %@.",
			nil, nil, nil, texturepath);
		return;
	}
	fprintf (stream, "numtextures: 0\n");
	fclose (stream);
	
	//
	// load in and init all the WAD patches
	//
	loaded = YES;
	
	if ( !wadfile_i )
		wadfile_i = [ Wadfile alloc ];

	[editworld_i	closeWorld];

	[sectorEdit_i	emptySpecialList];
	[linepanel_i	emptySpecialList];
	[thingpanel_i	emptyThingList];

	printf("Initializing WADfile %s\n",wadfile.UTF8String);
	[ wadfile_i	initFromFile: wadfile ];
	
	printf("Purging existing texture patches.\n");
	[ textureEdit_i	dumpAllPatches ];	
	[ textureEdit_i	initPatches ];
	
	numtextures = 0;
	[texturePalette_i	selectTexture:-1];
	[texturePalette_i	initTextures];
	[self updateTextures];		// TexturePalette will be updated in here
	[texturePalette_i	setupPalette];
	
	printf("Purging existing flats.\n");
	[ sectorEdit_i	dumpAllFlats ];
	[ sectorEdit_i	loadFlats ];
	[sectorEdit_i	setCurrentFlat:0];
	[sectorEdit_i	setupEditor];
	
	printf("Purging existing icons.\n");
	[ thingPalette_i	dumpAllIcons ];
	[ thingPalette_i	initIcons ];
	
	[ self		updateThings ];
	[ self		updateSectorSpecials ];
	[ self		updateLineSpecials ];
	[ self		updateTextures ];
	
	[ wadfile_i	close ];
	
	[self	setMapDirty:FALSE];
	[self	setProjectDirty:FALSE];
	[self menuTarget: self];		// bring the panel to front
}


/*
===============
=
= saveProject
=
===============
*/

- (IBAction)saveProject: sender
{
	FILE		*stream;
	NSString	*filename;

	if (!loaded)
		return;
	
	filename = [projectdirectory stringByAppendingPathComponent:@"project.dpr"];
	stream = fopen (filename.fileSystemRepresentation,"w");
	fprintf (stream, "Doom Project version 1\n");
	[self savePV1File: stream];
	fclose (stream);
	projectdirty = NO;

	[self updateTextures];
	[self	updateThings];
	[self	updateSectorSpecials];
	[self	updateLineSpecials];
	[texturePalette_i	finishInit];
	[self	saveDoomLumps];
	[self	setProjectDirty:FALSE];
}


/*
===============
=
= reloadProject
=
===============
*/

- (IBAction)reloadProject: sender
{
	if (!loaded)
		return;
		
	[self updateTextures];
	[self	updateThings];
	[self	updateSectorSpecials];
	[self	updateLineSpecials];
	[self	setProjectDirty:FALSE];
}


/*
=============================================================================

						PRIVATE METHODS
						
=============================================================================
*/

/*
===============
=
= updatePanel
=
===============
*/

- (void)updatePanel
{
	[projectpath_i setStringValue:
		projectdirectory];
	[wadpath_i setStringValue:
		wadfile];
	[BSPprogram_i setStringValue:
		[NSString stringWithUTF8String: bspprogram]];
	[BSPhost_i setStringValue:
		[NSString stringWithUTF8String: bsphost]];
	[mapwaddir_i setStringValue:
		[NSString stringWithUTF8String: mapwads]];
	[maps_i reloadColumn: 0];
}

- (void)changeWADfile:(char *)string
{
	self.wadFile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:string length:strlen(string)];
	[self	updatePanel];
	NSRunAlertPanel(@"Note!", @"The WADfile will be changed when you "
		"restart DoomEd.  Make sure you SAVE YOUR PROJECT!",
		@"OK", nil, nil);
}

/*
===============
=
= loadProject:
=
= Called by openProject:
=
===============
*/

- (BOOL)loadProject: (char const *)path
{
	NSString *aPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:path length:strlen(path)];
	return [self loadProjectAtPath:aPath error:NULL];
}

- (BOOL)loadProjectAtPath: (NSString *)path error:(NSError**)error
{
	FILE		*stream;
	NSString	*projpath;
	int			version, ret;
	int			oldnumtextures;
	
	self.directory = [path stringByDeletingLastPathComponent];
	
	projpath = projectdirectory;
	projpath = [projpath stringByAppendingPathComponent:@"project.dpr"];
	
	stream = fopen (projpath.fileSystemRepresentation,"r");
	if (!stream)
	{
		NSRunAlertPanel(@"Error", @"Couldn't open %@",
			nil, nil, nil, projpath);
		return NO;
	}
	version = -1;
	fscanf (stream, "Doom Project version %d\n", &version);
	if (version == 1)
		ret = [self loadPV1File: stream];
	else
	{
		fclose (stream);
		NSRunAlertPanel(@"Error",
			@"Unknown file version for project %@",
			nil, nil, nil, projpath);
		return NO;
	}

	if (!ret)
	{
		fclose (stream);
		NSRunAlertPanel(@"Error",
			@"Couldn't parse project file %@",
			nil, nil, nil, projpath);
		return NO;
	}
	
	fclose (stream);
	
	projectdirty = NO;
	texturesdirty = NO;
	loaded = YES;
	oldnumtextures = numtextures;
	wadfile_i = [[Wadfile alloc] initWithFilePath: wadfile];
	if (!wadfile_i)
	{
		NSRunAlertPanel(@"Error",
			@"Couldn't open wadfile %@",
			nil, nil, nil, wadfile);
		return NO;
	}
	
	[editworld_i	closeWorld];
	[log_i	msg:"DoomEd initializing...\n\n" ];
	
	[sectorEdit_i	emptySpecialList];
	[linepanel_i	emptySpecialList];
	[thingpanel_i	emptyThingList];
	
	[self	updateThings];
	[self	updateSectorSpecials];
	[self	updateLineSpecials];
	
	[self menuTarget: self];		// bring the panel to front
	
	[textureEdit_i	initPatches];
	numtextures = 0;
	[texturePalette_i	selectTexture:-1];
	[self updateTextures];		// TexturePalette will be updated in here
	[texturePalette_i	setupPalette];
	
	[sectorEdit_i	loadFlats];
	[sectorEdit_i	setCurrentFlat:0];
	[sectorEdit_i	setupEditor];
	
	[thingPalette_i	initIcons];
		
	[wadfile_i close];
	
	[self	setMapDirty:FALSE];
	[self	setProjectDirty:FALSE];
	return YES;
}


/*
=============================================================================

						MAP METHODS
						
=============================================================================
*/


/*
===============
=
= removeMap:
=
===============
*/

- (IBAction)removeMap:sender
{

}

//============================================================
//
//	Sort the maps internally
//
//============================================================
- sortMaps
{
	int i;
	int j;
	int flag;
	NSString *tmp;

	flag = 1;
	while(flag)
	{
		flag = 0;
		for(i=0;i<nummaps;i++)
		{
			for(j=i+1;j<nummaps;j++)
			{
				if ([mapnames[j] compare: mapnames[i]] < 0)
				{
					tmp = mapnames[i];
					mapnames[i] = mapnames[j];
					mapnames[j] = tmp;
					flag = 1;
					break;
				}
			}
		}
	}
	return self;
}

/*
===============
=
= browser:fillMatrix:inColumn:
=
===============
*/

- (NSInteger)browser:sender  fillMatrix:(NSMatrix*)matrix  inColumn:(NSInteger)column
{
	NSInteger	i;
	id	cell;

	if (column != 0)
		return 0;

	[self	sortMaps];
		
	for (i=0 ; i<nummaps ; i++)
	{
		[matrix addRow];
		cell = [matrix cellAtRow: i column: 0];
		[cell setStringValue: mapnames[i]];
		[cell setLeaf: YES];
		[cell setLoaded: YES];
		[cell setEnabled: YES];
	}
	
	return nummaps;
}

/*
=====================
=
= newMap
=
= A world name was typed in the new field
=
=====================
*/

- (IBAction)newMap: sender
{
	FILE *stream;
	NSString *pathname;
	NSString *title;
	int  len, i;

	//
	// get filename for map
	//	
	title = [mapNameField_i stringValue];
	len = [title length];
	if (len < 1 || len > 8)
	{
		NSRunAlertPanel(@"Error",
			@"Map names must be 1 to 8 characters",
			nil, nil, nil);
		return;
	}

	for (i=0 ; i<nummaps ; i++)
		if ([title compare: mapnames[i]] == 0)
		{
			NSRunAlertPanel(@"Error", @"Map name in use",
				nil, nil, nil);
			return;
		}

	//
	// write an empty file
	//
	pathname = [projectdirectory stringByAppendingPathComponent:title];
	pathname = [pathname stringByAppendingPathExtension:@"dwd"];
	stream = fopen (pathname.fileSystemRepresentation,"w");
	if (!stream)
	{
		NSRunAlertPanel(@"Error", @"Could not open %@",
			nil, nil, nil, pathname);
		return;
	}
	fprintf (stream, "WorldServer version 0\n");
	fclose (stream);

//
// add the map and update the browser
//
	mapnames[nummaps] = [title copy];
	nummaps++;

	[self updatePanel];
	[self saveProject: self];
}

/*
=====================
=
= openMap:
=
= A world name was clicked on in the browser
=
=====================
*/

- (IBAction)openMap:sender
{
	id cell;
	NSString *title;
	NSString *fullpath;
	NSString *string;

	if ([editworld_i loaded])
		[editworld_i closeWorld];
	
	cell = [sender selectedCell];
	title = [cell stringValue];
	
	fullpath = [projectdirectory stringByAppendingPathComponent:title];
	fullpath = [fullpath stringByAppendingPathExtension:@"dwd"];
	
	string = [NSString stringWithFormat:@"\nLoading map %@\n", title];
	[ log_i	addLogString:string ];
	[editworld_i loadWorldFile: fullpath];
}

//===================================================================
//
//	Load Map Functions
//
//===================================================================
static NSInteger	oldSelRow,curMap;
id	openMatrix;

//	Init to start opening all maps
- (void)beginOpenAllMaps
{
	openMatrix = [maps_i	matrixInColumn:0];
	oldSelRow = [openMatrix	selectedRow];
	curMap = 0;
}

//	Open next map, finish if needed
- (BOOL)openNextMap
{
	if (curMap < nummaps)
	{
		[openMatrix	selectCellAtRow:curMap column:0];
		[self	openMap:openMatrix];
		curMap++;
		return YES;
	}
	else
	{
		if (oldSelRow >= 0)
		{
			[openMatrix	selectCellAtRow:oldSelRow column:0];
			[self	openMap:openMatrix];
		}
		return NO;
	}
}

//===================================================================
//
//	Print all the maps out!
//
//===================================================================
- (IBAction)printAllMaps:sender
{
	id			openMatrix;
	NSInteger	i;
	NSInteger	selRow;

	[editworld_i	closeWorld];

	openMatrix = [maps_i	matrixInColumn:0];
	selRow = [openMatrix	selectedRow];
	
	for (i = 0;i < nummaps; i++)
	{
		[openMatrix	selectCellAtRow:i column:0];
		[self	openMap:openMatrix];
		[self	printMap:NULL];
	}
	
	if (selRow >=0)
	{
		[openMatrix	selectCellAtRow:selRow column:0];
		[self	openMap:openMatrix];
	}
}

//===================================================================
//
//	Map printing preferences
//
//===================================================================
- (IBAction)printPrefs:sender
{
	[printPrefWindow_i	makeKeyAndOrderFront:NULL];
}

- (IBAction)togglePanel:sender
{
	pp_panel = 1-pp_panel;
}
- (IBAction)toggleItems:sender
{
	pp_items = 1-pp_items;
}
- (IBAction)toggleMonsters:sender
{
	pp_monsters = 1-pp_monsters;
}
- (IBAction)toggleWeapons:sender
{
	pp_weapons = 1-pp_weapons;
}

//===================================================================
//
//	Print the map out!
//
//===================================================================
- (IBAction)printMap:sender
{
	char	string[1024];
	id		m;
	id		cell;
	id		panel;
	char	prpanel[10];
	char	monsters[10];
	char	items[10];
	char	weapons[10];
	
	m = [maps_i	matrixInColumn:0];
	cell = [m selectedCell];
	if (!cell)
	{
		NSBeep();
		return;
	}
	
	memset(prpanel,0,10);
	memset(monsters,0,10);
	memset(items,0,10);
	memset(weapons,0,10);
	
	if (pp_panel)
		strcpy(prpanel,"-panel");
	if (pp_weapons)
		strcpy(weapons,"-weapons");
	if (pp_items)
		strcpy(items,"-powerups");
	if (pp_monsters)
		strcpy(monsters,"-monsters");
		
	sprintf(string,"doomprint %s %s %s %s %s/%s.dwd",
		prpanel,
		weapons,
		items,
		monsters,
		projectdirectory.fileSystemRepresentation,
		[[cell stringValue] UTF8String]);

	panel = NSGetAlertPanel(@"Wait...",
		@"Printing %@.",
		nil, nil, nil,
		[cell stringValue]);

	[panel	orderFront:NULL];
	NXPing();
	system(string);
	[panel	orderOut:NULL];
	NSReleaseAlertPanel(panel);
}

//===================================================================
//
// 				MAP MUNGE: LOAD AND SAVE ALL MAPS
//
//===================================================================
- (IBAction)loadAndSaveAllMaps:sender
{
	id			openMatrix;
	NSInteger	i;
	NSInteger	selRow;

#if 0
	rv = NSRunAlertPanel(@"Warning!",
		@"This may take awhile!  Make sure your map is saved!",
		@"Abort", @"Continue", nil, nil);
	if (rv == 1)
		return self;
#endif
	[editworld_i	closeWorld];

	openMatrix = [maps_i	matrixInColumn:0];
	selRow = [openMatrix	selectedRow];
	
	for (i = 0;i < nummaps; i++)
	{
		[openMatrix	selectCellAtRow:i column:0];
		[self	openMap:openMatrix];
		[editworld_i	saveDoomEdMapBSP:NULL];
	}
	
	if (selRow >=0)
	{
		[openMatrix	selectCellAtRow:selRow column:0];
		[self	openMap:openMatrix];
	}
}

//===================================================================
//
// 							PRINT CURRENT MAP'S STATISTICS
//
//===================================================================
typedef struct
{
	int		type;
	int		count;
	char	name[32];
} tc_t;

- (IBAction)printSingleMapStatistics:sender
{
	int		i,nt,k;
	int		tset;
	int		*textureCount, indx;
	FILE		*stream;
	NSString *filename = @"/tmp/tempstats.txt";
	texpal_t	*t;
	id		openMatrix;
	NSInteger		selRow;
	char		string[80];
	int		numth;
	tc_t	*thingCount;
	
	if ([editworld_i	loaded] == NO)
	{
		NSRunAlertPanel(@"Hey!",
			@"You don't have a world loaded!",
			@"Oops, what a dolt I am!", nil, nil);
		return;
	}
	
	[ log_i	addLogString:@"Single map statistics\n" ];

	//
	//	Thing report data
	//
	numth = numthings;	// MAX # OF DIFFERENT TYPES OF THINGS POSSIBLE
	thingCount = malloc (numth * sizeof(*thingCount));
	bzero(thingCount,sizeof(*thingCount)*numth);
	for (i = 0;i < numth;i++)
	{
		int	type = things[i].type;
		int	found = 0;
		int	j;
		
		// IF TYPE ALREADY EXISTS IN ARRAY, INC COUNT
		for (j = 0;j < numth;j++)
		{
			if (thingCount[j].type == type)
			{
				thingCount[j].count++;
				found = 1;
				break;
			}
		}
		
		// IF TYPE !EXIST, CREATE TYPE AND COUNT = 1
		if (!found)
			for (j = 0;j < numth;j++)
				if (!thingCount[j].type)
				{
					int	index;
					thinglist_t *thing;
					
					thingCount[j].type = type;
					thingCount[j].count = 1;
					
					index = [thingPanel_i searchForThingType:type];
					thing = [thingPanel_i getThingData:index];
					strcpy(thingCount[j].name,thing->name);
					
					break;
				}
	}

	//
	//	Texture report data
	//
	nt = [texturePalette_i	getNumTextures];
	textureCount = malloc(sizeof(int) * nt);
	bzero(textureCount,sizeof(int)*nt);
	
	//
	// count amount of each texture
	//
	for (k=0;k<numlines;k++)
	{
		if (lines[k].selected == -1)		// deleted line; skip it
			continue;
			
		// SIDE 0
		//
		// BOTTOM
		//
		indx = [texturePalette_i
				getTextureIndex:lines[k].side[0].bottomtexture];
		if (indx >= nt)
			NSRunAlertPanel(@"Programming Error?",
				@"Returned a bad texture index: %d",
				@"Continue", nil, nil, indx);
		
		if (indx >= 0)
			textureCount[indx]++;
		else
		if (indx == -2)
		{
			NSRunAlertPanel(@"Error!",
				@"Found a line with a texture that isn't present: '%s'",
				@"Continue", nil, nil, lines[k].side[0].bottomtexture);
			[editworld_i	selectLine:k];
			sprintf(string,"Line %d: texture '%s' nonexistent!\n",
				k, lines[k].side[0].bottomtexture);
			[log_i	msg:string];
			return;
		}

		//
		// MIDDLE
		//
		indx = [texturePalette_i
				getTextureIndex:lines[k].side[0].midtexture];
		if (indx >= nt)
			NSRunAlertPanel(@"Programming Error?",
				@"Returned a bad texture index: %d",
				@"Continue", nil, nil, indx);
		if (indx >= 0)
			textureCount[indx]++;
		else
		if (indx == -2)
		{
			NSRunAlertPanel(@"Error!",
				@"Found a line with a texture that isn't present: '%s'",
				@"Continue", nil, nil, lines[k].side[0].midtexture);
			[editworld_i	selectLine:k];
			sprintf(string,"Line %d: texture '%s' nonexistent!\n",
				k, lines[k].side[0].midtexture);
			[log_i	msg:string];
			return;
		}

		//
		// TOP
		//
		indx = [texturePalette_i
				getTextureIndex:lines[k].side[0].toptexture];
		if (indx >= nt)
			NSRunAlertPanel(@"Programming Error?",
				@"Returned a bad texture index: %d",
				@"Continue", nil, nil, indx);
		if (indx >= 0)
			textureCount[indx]++;
		else
		if (indx == -2)
		{
			NSRunAlertPanel(@"Error!",
				@"Found a line with a texture that isn't present: '%s'",
				@"Continue", nil, nil, lines[k].side[0].toptexture);
			[editworld_i	selectLine:k];
			sprintf(string,"Line %d: texture '%s' nonexistent!\n",
				k, lines[k].side[0].toptexture);
			[log_i	msg:string];
			return;
		}

		// SIDE 1
		//
		// BOTTOM
		//
		indx = [texturePalette_i
				getTextureIndex:lines[k].side[1].bottomtexture];
		if (indx >= nt)
			NSRunAlertPanel(@"Programming Error?",
				@"Returned a bad texture index: %d",
				@"Continue", nil, nil, indx);
		
		if (indx >= 0)
			textureCount[indx]++;
		else
		if (indx == -2)
		{
			NSRunAlertPanel(@"Error!",
				@"Found a line with a texture that isn't present: '%s'",
				@"Continue", nil, nil, lines[k].side[1].bottomtexture);
			[editworld_i	selectLine:k];
			sprintf(string,"Line %d: texture '%s' nonexistent!\n",
				k, lines[k].side[0].bottomtexture);
			[log_i	msg:string];
			return;
		}

		//
		// MIDDLE
		//
		indx = [texturePalette_i
				getTextureIndex:lines[k].side[1].midtexture];
		if (indx >= nt)
			NSRunAlertPanel(@"Programming Error?",
				@"Returned a bad texture index: %d",
				@"Continue", nil, nil, indx);
		if (indx >= 0)
			textureCount[indx]++;
		else
		if (indx == -2)
		{
			NSRunAlertPanel(@"Error!",
				@"Found a line with a texture that isn't present: '%s'",
				@"Continue", nil, nil, lines[k].side[1].midtexture);
			[editworld_i	selectLine:k];
			sprintf(string,"Line %d: texture '%s' nonexistent!\n",
				k, lines[k].side[0].midtexture);
			[log_i	msg:string];
			return;
		}

		//
		// TOP
		//
		indx = [texturePalette_i
				getTextureIndex:lines[k].side[1].toptexture];
		if (indx >= nt)
			NSRunAlertPanel(@"Programming Error?",
				@"Returned a bad texture index: %d",
				@"Continue", nil, nil, indx);
		if (indx >= 0)
			textureCount[indx]++;
		else
		if (indx == -2)
		{
			NSRunAlertPanel(@"Error!",
				@"Found a line with a texture that isn't present: '%s'",
				@"Continue", nil, nil, lines[k].side[1].toptexture);
			[editworld_i	selectLine:k];
			sprintf(string,"Line %d: texture '%s' nonexistent!\n",
				k, lines[k].side[0].toptexture);
			[log_i	msg:string];
			return;
		}
	}
		
	//
	// create stats file
	//
	openMatrix = [maps_i matrixInColumn:0];
	selRow = [openMatrix	selectedRow];

	stream = fopen([filename fileSystemRepresentation], "w");
	fprintf(stream,"DoomEd Map Statistics for %s\n\n",
		[[openMatrix cellAtRow:selRow column:0] stringValue].UTF8String);
	fprintf(stream,"Texture count:\n");
	tset = -1;
	for (i=0;i<nt;i++)
	{
		if (!textureCount[i])
			continue;
		t = [texturePalette_i	getTexture:i];
		if (t->WADindex != tset)
		{
			fprintf(stream,"Texture set #%d\n",t->WADindex+1);
			tset = t->WADindex;
		}
		fprintf(stream,"%d\x9\x9%s\n",textureCount[i],t->name);
	}
	
	fprintf(stream,"\nThing Report:\n");
	fprintf(stream, "Type	Amount	Description\n"
					"-----	------	-------------------------------------\n");
	for (i = 0;i < numth;i++)
		if (thingCount[i].type)
			fprintf(stream,"%d   \x9\x9%d\x9%s\n",
				thingCount[i].type,
				thingCount[i].count,
				thingCount[i].name);

	fclose(stream);

	//
	// launch Edit with file!
	//
	[[NSWorkspace sharedWorkspace] openFile:filename];

	free(textureCount);
}

//===================================================================
//
// 							PRINT ALL MAP STATISTICS
//
//===================================================================
- (IBAction)printStatistics:sender
{
	id		openMatrix;

	int		numPatches;
	int		*patchCount;
	char	*patchName;
	
	int		i;
	int		k;
	int		j;
	int		nt;
	NSInteger	selRow;
	int		nf;
	int		flat;
	int		errors;
	int		*textureCount, indx, *flatCount;
	FILE	*stream;
	NSString *filename = @"/tmp/tempstats.txt";
	char	string[80];
	texpal_t	*t;
	int	numth;
	tc_t	*thingCount;
	CompatibleStorage* thingList_i;
	
#if 0
	rv = NSRunAlertPanel(@"Warning!",
		@"This may take awhile!  Make sure your map is saved!",
		@"Abort", @"Continue", nil, nil);
	if (rv == 1)
		return self;
#endif
	[editworld_i	closeWorld];

	openMatrix = [maps_i	matrixInColumn:0];
	selRow = [openMatrix	selectedRow];
	
	nt = [texturePalette_i	getNumTextures];
	textureCount = malloc(sizeof(int) * nt);
	bzero(textureCount,sizeof(int)*nt);
	
	nf = [sectorEdit_i	getNumFlats];
	flatCount = malloc ( sizeof(*flatCount) * nf );
	bzero (flatCount, sizeof (*flatCount) * nf );

	thingList_i = [thingPanel_i getThingList];
	numth = [thingList_i	count];
	thingCount = malloc (numth * sizeof(*thingCount));
	bzero(thingCount,sizeof(*thingCount)*numth);
	// FILL THING COUNT LIST WITH ALL POSSIBLE THINGS
	for (k = 0;k < numth;k++)
	{
		thinglist_t *thing;
		thing = [thingPanel_i getThingData:k];
		thingCount[k].type = thing->value;
		strcpy(thingCount[k].name,thing->name);
	}
	
	[log_i addLogString:@"Starting to calculate multiple map statistics...\n" ];
	
	errors = 0;
	
	for (i = 0;i < nummaps; i++)
	{
		sprintf(string,"Loading map %s.\n",
			[[[openMatrix selectedCell] stringValue] UTF8String]);
		[log_i	msg:string ];
		[openMatrix	selectCellAtRow:i column:0];
		[self	openMap:openMatrix];
		
		//
		//	Thing report data
		//
		[log_i addLogString:@"Counting things.\n"];
		for (k = 0;k < numthings;k++)
		{
			int	type = things[k].type;
			int	found = 0;
			int	j;
			
			// IF TYPE ALREADY EXISTS IN ARRAY, INC COUNT
			for (j = 0;j < numth;j++)
			{
				if (thingCount[j].type == type)
				{
					thingCount[j].count++;
					found = 1;
					break;
				}
			}
			
			// IF TYPE !EXIST, CREATE TYPE AND COUNT = 1
			if (!found)
				for (j = 0;j < numth;j++)
					if (!thingCount[j].type)
					{
						int	index;
						thinglist_t *thing;
						
						thingCount[j].type = type;
						thingCount[j].count = 1;
						
						index = [thingPanel_i searchForThingType:type];
						thing = [thingPanel_i getThingData:index];
						strcpy(thingCount[j].name,thing->name);
						
						break;
					}
		}
		
		//
		// count amount of each texture
		//
		[log_i addLogString:@"Counting textures and flats.\n"];
		for (k=0;k<numlines;k++)
		{
			// SIDE 0
			indx = [texturePalette_i
					getTextureIndex:lines[k].side[0].bottomtexture];

			if (indx >= nt)
				NSRunAlertPanel(@"Programming Error?",
					@"Returned a bad texture index: %d",
					@"Continue", nil, nil, indx);

			if (indx >= 0)
			{
				textureCount[indx]++;
			}
			else if (indx == -2)
			{
				NSString *orgname = [NSString stringWithUTF8String:
					lines[k].side[0].bottomtexture];
				[textureRemapper_i addToList: orgname to: @"???"];
				errors++;
			}

			indx = [texturePalette_i
					getTextureIndex:lines[k].side[0].midtexture];
			if (indx >= nt)
				NSRunAlertPanel(@"Programming Error?",
					@"Returned a bad texture index: %d",
					@"Continue", nil, nil, indx);
			if (indx >= 0)
			{
				textureCount[indx]++;
			}
			else if (indx == -2)
			{
				NSString *orgname = [NSString stringWithUTF8String:
					lines[k].side[0].midtexture];

				[textureRemapper_i addToList: orgname to: @"???"];
				errors++;
			}

			indx = [texturePalette_i
					getTextureIndex:lines[k].side[0].toptexture];
			if (indx >= nt)
				NSRunAlertPanel(@"Programming Error?",
					@"Returned a bad texture index: %d",
					@"Continue", nil, nil, indx);
			if (indx >= 0)
			{
				textureCount[indx]++;
			}
			else if (indx == -2)
			{
				NSString *orgname = [NSString stringWithUTF8String:
					lines[k].side[0].toptexture];

				[textureRemapper_i addToList: orgname to: @"???"];
				errors++;
			}

			if (lines[k].side[0].ends.floorflat[0])
			{
				flat = [ sectorEdit_i
					findFlat:lines[k].side[0].ends.floorflat ];
				if (flat >= 0)
				{
					flatCount[flat]++;
				}
				else
				{
					NSString *orgname = [NSString stringWithUTF8String:
						lines[k].side[0].ends.floorflat];
					[flatRemapper_i addToList: orgname to: @"???"];
					errors++;
				}
			}
			if (lines[k].side[0].ends.ceilingflat[0])
			{
				flat = [ sectorEdit_i
					findFlat:lines[k].side[0].ends.ceilingflat ];
				if (flat >= 0)
				{
					flatCount[flat]++;
				}
				else
				{
					NSString *orgname = [NSString stringWithUTF8String:
						lines[k].side[0].ends.ceilingflat];

					[flatRemapper_i addToList: orgname to: @"???"];
					errors++;
				}
			}

			// SIDE 1
			indx = [texturePalette_i
					getTextureIndex:lines[k].side[1].bottomtexture];
			if (indx >= nt)
				NSRunAlertPanel(@"Programming Error?",
					@"Returned a bad texture index: %d",
					@"Continue", nil, nil, indx);

			if (indx >= 0)
			{
				textureCount[indx]++;
			}
			else if (indx == -2)
			{
				NSString *orgname = [NSString stringWithUTF8String:
					lines[k].side[1].bottomtexture];

				[textureRemapper_i addToList: orgname to: @"???"];
				errors++;
			}

			indx = [texturePalette_i
					getTextureIndex:lines[k].side[1].midtexture];
			if (indx >= nt)
				NSRunAlertPanel(@"Programming Error?",
					@"Returned a bad texture index: %d",
					@"Continue", nil, nil, indx);
			if (indx >= 0)
			{
				textureCount[indx]++;
			}
			else if (indx == -2)
			{
				NSString *orgname = [NSString stringWithUTF8String:
					lines[k].side[1].midtexture];

				[textureRemapper_i addToList: orgname to: @"???"];
				errors++;
			}

			indx = [texturePalette_i
					getTextureIndex:lines[k].side[1].toptexture];
			if (indx >= nt)
				NSRunAlertPanel(@"Programming Error?",
					@"Returned a bad texture index: %d",
					@"Continue", nil, nil, indx);
			if (indx >= 0)
			{
				textureCount[indx]++;
			}
			else if (indx == -2)
			{
				NSString *orgname = [NSString stringWithUTF8String:
					lines[k].side[1].toptexture];

				[textureRemapper_i addToList: orgname to: @"???"];
				errors++;
			}

			if (lines[k].side[1].ends.floorflat[0])
			{
				flat = [ sectorEdit_i
					findFlat:lines[k].side[1].ends.floorflat ];
				if (flat >= 0)
				{
					flatCount[flat]++;
				}
				else
				{
					NSString *orgname = [NSString stringWithUTF8String:
						lines[k].side[1].ends.floorflat];

					[flatRemapper_i addToList: orgname  to: @"???"];
					errors++;
				}
			}
			
			if (lines[k].side[1].ends.ceilingflat[0])
			{
				flat = [ sectorEdit_i
						findFlat:lines[k].side[1].ends.ceilingflat ];
				if (flat >= 0)
				{
					flatCount[flat]++;
				}
				else
				{
					NSString *orgname = [NSString stringWithUTF8String:
						lines[k].side[1].ends.ceilingflat];
					[flatRemapper_i addToList: orgname  to: @"???"];
					errors++;
				}
			}
		}
	}
	
	if (errors)
		NSRunAlertPanel(@"Errors!",
			@"Found %d lines with textures or flats that aren't present.\n"
			"The Texture/Flat Remappers have these errors listed so you\n"
			"can fix them.",
			@"Continue", nil, nil, errors);

	//
	// 	Create Stats file
	//
	stream = fopen([filename UTF8String], "w");
	fprintf(stream,"DoomEd Map Statistics\n\n");

	fprintf(stream,"Number of textures in project:%d\n",nt);
	fprintf(stream,"Texture count:\n");
	for (i=0;i<nt;i++)
	{
		t = [texturePalette_i	getTexture:i];
		fprintf(stream,"Texture\x9\x9%d\x9\x9\x9%s\n",textureCount[i],t->name);
	}
	
	//
	//	Count flat usage
	//
	fprintf( stream, "Number of flats in project:%d\n",nf );
	fprintf( stream, "Flat count:\n" );
	for (i = 0; i < nf; i++)
		fprintf( stream, "Flat\x9\x9%d\x9\x9\x9%s\n",flatCount[i],
			[[sectorEdit_i flatName:i] UTF8String]);
	
	//
	//	Print thing report
	//
	fprintf(stream,"\nThing Report:\n");
	fprintf(stream, "Type	Amount	Description\n"
					"-----	------	-------------------------------------\n");
	for (i = 0;i < numth;i++)
		if (thingCount[i].type)
			fprintf(stream,"%d   \x9\x9%d\x9%s\n",
				thingCount[i].type,
				thingCount[i].count,
				thingCount[i].name);
	
	//
	//	Count patch usage
	//
	[log_i	msg:"Calculating patch usage: " ];
	numPatches = [textureEdit_i	getNumPatches];
	patchCount = malloc(sizeof(*patchCount) * numPatches);
	bzero(patchCount,sizeof(*patchCount)* numPatches);
	
	fprintf(stream, "Number of patches in project:%d\n",numPatches);
	fprintf(stream, "Patch count:\n");
	for (i = 0;i < numPatches; i++)
	{
		[log_i	msg:"." ];
		patchName = [textureEdit_i  getPatchName:i];
		for (j = 0;j < numtextures; j++)
			for (k = 0;k < textures[j].patchcount; k++)
				if (!strcasecmp(patchName,textures[j].patches[k].patchname))
					patchCount[i]++;
		fprintf(stream, "Patch\x9\x9\x9%d\x9\x9\x9%s\n",
			patchCount[i],patchName);
	}

	//
	//	Done!
	//
	fclose(stream);
	[log_i	msg:"\nFinished!\n\n" ];

	//
	// launch Edit with file!
	//
	[[NSWorkspace sharedWorkspace] openFile:filename];

	free(textureCount);
	free(flatCount);

	if (selRow >=0)
	{
		[openMatrix	selectCellAtRow:selRow column:0];
		[self	openMap:openMatrix];
	}
}

//======================================================================
//
//	THING METHODS
//
//======================================================================
- (BOOL)updateThings
{
	FILE		*stream;
	NSString	*filename;
	int			handle;

	filename = [projectdirectory stringByAppendingPathComponent:@"things.dsp"];
	
	handle = open (filename.fileSystemRepresentation, O_CREAT | O_RDWR, 0666);
	if (handle == -1)
	{
		NSRunAlertPanel(@"Error", @"Couldn't open %@",
			nil, nil, nil, filename);
		return NO;
	}		

	flock (handle, LOCK_EX);
	
	stream = fdopen (handle,"r+");
	if (!stream)
	{
		fclose (stream);
		NSRunAlertPanel(@"Error", @"Could not stream to %@",
			nil, nil, nil, filename);
		return NO;
	}
	
	printf("Updating things file\n");
	[thingPanel_i	updateThingsDSP:stream];
	flock(handle,LOCK_UN);
	fclose(stream);
	
	return YES;
}

//======================================================================
//
//	SPECIAL METHODS
//
//======================================================================
- (BOOL)updateSectorSpecials
{
	FILE		*stream;
	NSString	*filename;
	int			handle;

	filename = [projectdirectory stringByAppendingPathComponent:@"sectorspecials.dsp"];
	
	handle = open (filename.fileSystemRepresentation, O_CREAT | O_RDWR, 0666);
	if (handle == -1)
	{
		NSRunAlertPanel(@"Error", @"Couldn't open %@",
			nil, nil, nil, filename);
		return NO;
	}		

	flock (handle, LOCK_EX);
	
	stream = fdopen (handle,"r+");
	if (!stream)
	{
		fclose (stream);
		NSRunAlertPanel(@"Error", @"Could not stream to %@",
			nil, nil, nil, filename);
		return NO;
	}
	
	printf("Updating Sector Specials file\n");
	[sectorEdit_i	updateSectorSpecialsDSP:stream];
	flock(handle,LOCK_UN);
	fclose(stream);
	
	return YES;
}

- (BOOL)updateLineSpecials
{
	FILE		*stream;
	NSString	*filename;
	int			handle;
	
	filename = [projectdirectory stringByAppendingPathComponent:@"linespecials.dsp"];
	
	handle = open (filename.fileSystemRepresentation, O_CREAT | O_RDWR, 0666);
	if (handle == -1)
	{
		NSRunAlertPanel(@"Error", @"Couldn't open %@",
			nil, nil, nil, filename);
		return NO;
	}		

	flock (handle, LOCK_EX);
	
	stream = fdopen (handle,"r+");
	if (!stream)
	{
		fclose (stream);
		NSRunAlertPanel(@"Error", @"Could not stream to %@",
			nil, nil, nil, filename);
		return NO;
	}
	
	printf("Updating Line Specials file\n");
	[linepanel_i	updateLineSpecialsDSP:stream];
	flock(handle,LOCK_UN);
	fclose(stream);
	
	return YES;
}

/*
=============================================================================

						TEXTURE METHODS
						
=============================================================================
*/

//=========================================================
//
//	Alphabetize the textures[] array
//
//=========================================================
- alphabetizeTextures:(int)sets
{
	int x;
	int y;
	int found;
	CompatibleStorage *store;
	worldtexture_t *t;
	worldtexture_t *t2;
	worldtexture_t m;
	worldtexture_t m2;
	int max;
	int windex;
	NSMutableArray *list;

	printf("Alphabetize textures.\n");
	printf("numtextures = %d\n",numtextures);
	list = [[NSMutableArray alloc] init];

	for (windex = 0; windex <= sets; windex++)
	{
		store = [[CompatibleStorage alloc]
			initCount: 0
			elementSize: sizeof(worldtexture_t)
			description: NULL
		];

		for (x = 0;x < numtextures;x++)
			if (textures[x].WADindex == windex)
				[store	addElement:&textures[x]];
		
		max = [store count];
		do
		{
			found = 0;
			for (x = 0;x < max - 1;x++)
				for (y = x + 1;y < max;y++)
				{
					t = [store	elementAt:x];
					t2 = [store	elementAt:y];
					if (strcasecmp(t->name,t2->name) > 0)
					{
						m = *t;
						m2 = *t2;
						[store	replaceElementAt:x with:&m2];
						[store	replaceElementAt:y with:&m];
						found = 1;
						break;
					}
				}
			
		} while(found);

		[list addObject:store];

#if 0
		max = [store count];
		printf("\n%d textures in set %d:\n",max,windex);
		for (x = 0;x < max;x++)
			printf("%s\n",((worldtexture_t *)[store elementAt:x])->name);
#endif			
	}
	
	//	Store textures in textures[] array
	windex = 0;
	for (x = 0;x <= sets;x++)
	{
		store = [list objectAtIndex:x];
		max = [store count];
		for (y = 0;y < max;y++, windex++)
		{
			t = [store elementAt:y];
			textures[windex] = *t;
		}
		[store empty];
	}

	[list removeAllObjects];

	return self;
}

/*
=================
=
= read/writeTexture
=
=================
*/

- (BOOL)readTexture: (worldtexture_t *)tex from: (FILE *)file
{
	int	i;
	worldpatch_t	*patch;
	
	memset (tex, 0, sizeof(*tex));

	if (fscanf (file,"%s %d, %d, %d\n",
		tex->name, &tex->width, &tex->height, &tex->patchcount) != 4)
		return NO;
		
	for (i=0 ; i<tex->patchcount ; i++)
	{
		patch = &tex->patches[i];
		if (fscanf (file,"   (%d, %d : %s ) %d, %d\n",
			&patch->originx, &patch->originy,
			patch->patchname, &patch->stepdir, &patch->colormap) != 5)
			return NO;
	}

	return YES;
}

- (void)writeTexture: (worldtexture_t *)tex to: (FILE *)file
{
	int	i;
	worldpatch_t	*patch;
	
	fprintf (file,"%s %d, %d, %d\n",
		tex->name, tex->width, tex->height, tex->patchcount);
		
	for (i=0 ; i<tex->patchcount ; i++)
	{
		patch = &tex->patches[i];
		fprintf (file,"   (%d, %d : %s ) %d, %d\n",
			patch->originx, patch->originy,
			patch->patchname, patch->stepdir, patch->colormap);
	}
}


/*
================
=
= textureNamed:
=
= Returns the number of the data with the given name, -1 if no texture, -2 if  name not found
=
================
*/

- (int)textureNamed: (NSString *)name
{
	int	i;
	
	if (name.length == 0 || [name isEqualToString:@"-"] )
		return -1;		// no texture
	
	const char *cName = [name UTF8String];
	for (i=0 ; i<numtextures ; i++)
		if (!strcasecmp(textures[i].name, cName) )
			return i;
	return -2;	
}


/*
===============
=
= updateTextures
=
= Opens textures.dsp from the project directory exclusively, then reads in any new
= changes, then writes everything back out
=
===============
*/

- (void)updateTextures
{
	FILE	*stream;
	int		handle;
	NSString	*filename;
	int		count;
	int		i;
	int		num;
	worldtexture_t		tex;
	int		winmax;
	int		windex;
	int		wincount;
	int		newtexture;
	id		panel;
	

	//
	//	Read-in and update textures IN MEMORY
	//
	newtexture = windex = 0;
	do
	{
		panel = NSGetAlertPanel(@"Wait...",
			@"Reading textures from texture%d.dsp.",
			nil, nil, nil, windex+1);
		[panel	orderFront:NULL];
		NXPing();

		filename = [projectdirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"texture%d.dsp", windex+1]];

		chmod (filename.fileSystemRepresentation,0666);
		handle = open (filename.fileSystemRepresentation,O_RDWR, 0666);
		if (handle == -1)
		{
			if (!windex)
			{
				[panel	orderOut:NULL];
				NSReleaseAlertPanel(panel);
				NXPing();
				NSRunAlertPanel(@"Error", @"Couldn't open %@",
					nil, nil, nil, filename);
				return;
			}
			else
			{
				[panel	orderOut:NULL];
				NSReleaseAlertPanel(panel);
				NXPing();
				close(handle);
				windex = -1;
				continue;
			}
		}
	
		printf ("Updating textures in memory from Texture%d file\n",windex+1);
		flock (handle, LOCK_EX);

		stream = fdopen (handle,"r+");
		if (!stream)
		{
			close (handle);
			[panel	orderOut:NULL];
			NSReleaseAlertPanel(panel);
			NXPing();
			NSRunAlertPanel(@"Error", @"Could not stream to %@",
				nil, nil, nil, filename);
			return;
		}

		//
		// read textures out of the file
		//
		if (fscanf (stream, "numtextures: %d\n", &count) == 1)
		{
			for (i=0 ; i<count ; i++)
			{
				if (![self readTexture: &tex from: stream])
				{
					fclose (stream);
					[panel	orderOut:NULL];
					NSReleaseAlertPanel(panel);
					NXPing();
					NSRunAlertPanel(@"Error",
						@"Could not parse %@",
						nil, nil, nil,
						filename);
					return;
				}

				//
				// if the name is present but not modified, update it
				//	...to the current value
				// if the name is present and modified, don't update it
				// if the name is not present, add it
				//
				num = [self textureNamed:@(tex.name)];
				if (num == -2)
				{
					[self newTexture: &tex];
					num = [self	textureNamed:@(tex.name) ];
					textures[num].WADindex = windex;
					newtexture = 1;
				}
				else
				{
					tex.WADindex = windex;
					if (!textures[num].dirty)
						[self changeTexture: num to: &tex];
				}
			}
			
			windex++;
		}
		else
			windex = -1;
		
		flock (handle, LOCK_UN);
		fclose (stream);

		[panel	orderOut:NULL];
		NSReleaseAlertPanel(panel);
		NXPing();

	} while (windex >= 0);

	//
	//	Count how many sets of textures are in memory now
	//
	winmax = 0;
	for (i = 0; i < numtextures; i++)
		if (textures[i].WADindex > winmax)
			winmax = textures[i].WADindex;

	//
	//	Alphabetize textures
	//
	[self	alphabetizeTextures:winmax];

	//
	//	Write out all Texture?.dsp files needed
	//
	for (windex = 0; windex <= winmax; windex++)
	{
		panel = NSGetAlertPanel(@"Wait...",
			@"Writing textures to texture%d.dsp.",
			nil, nil, nil, windex+1);
		[panel	orderFront:NULL];
		NXPing();

		filename = [projectdirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"texture%d.dsp", windex+1]];

		BackupFile(filename);
		unlink(filename.fileSystemRepresentation);
		handle = open (filename.fileSystemRepresentation,O_CREAT | O_RDWR, 0666);
		if (handle == -1)
		{
			if (!windex)
			{
				[panel	orderOut:NULL];
				NSReleaseAlertPanel(panel);
				NXPing();
				NSRunAlertPanel(@"Error",
					@"Couldn't create %@",
					nil, nil, nil, filename);
				return;
			}
			else
			{
				[panel	orderOut:NULL];
				NSReleaseAlertPanel(panel);
				NXPing();
				close(handle);
				break;
			}
		}
	
		fchmod (handle,0666);
		flock (handle, LOCK_EX);
		
		stream = fdopen (handle,"r+");
		if (!stream)
		{
			fclose (stream);
			[panel	orderOut:NULL];
			NSReleaseAlertPanel(panel);
			NXPing();
			NSRunAlertPanel(@"Error",
				@"Could not stream to %@",
				nil, nil, nil, filename);
			return;
		}
		
		//
		//	Count how many of current set are in memory
		//
		wincount = 0;
		for (i = 0; i < numtextures; i++)
			if (textures[i].WADindex == windex)
				wincount++;

		//
		// go back to the beginning and write all the textures out
		//
		printf ("Writing Texture%d file\n",windex+1);
		texturesdirty = NO;
		fprintf (stream, "numtextures: %d\n",wincount);
		
		for (i=0 ; i<numtextures ; i++)
			if (textures[i].WADindex == windex)
			{
				textures[i].dirty = NO;
				[self writeTexture: &textures[i] to: stream];
			}
		
		flock (handle, LOCK_UN);
		fclose (stream);

		[panel	orderOut:NULL];
		NSReleaseAlertPanel(panel);
		NXPing();
	}		
	
	if (newtexture)
		[texturePalette_i	initTextures ];
}


/*
===============
=
= newTexture
=
===============
*/

- (int)newTexture: (worldtexture_t *)tex
{
	if (numtextures == texturessize)
	{
		texturessize += 32;		// add space to array
		textures = realloc (textures, texturessize*sizeof(worldtexture_t));
	}
	numtextures++;
	[self changeTexture: numtextures-1 to: tex];
	return numtextures-1;
}


/*
===============
=
= changeTexture
=
===============
*/

- (void)changeTexture: (int)num to: (worldtexture_t *)tex
{
	texturesdirty = YES;
	textures[num] = *tex;
	textures[num].dirty = YES;
}



/*
=============================================================================

						DOOM METHODS
						
=============================================================================
*/

static	int		lumptopatchnum[4096];
static	byte		*buffer, *buf_p;

- (byte *)getBuffer
{
	buffer = malloc (100000);
	return buffer;
}

/*
================
=
= writeBuffer
=
================
*/

- (void)writeBuffer: (NSString *)filename
{
	int			size;
	FILE		*stream;
	NSString	*directory;
	
	//self.wadFile =
	directory = [wadfile stringByDeletingLastPathComponent];
	chdir (directory.fileSystemRepresentation);
	
	size = (int)(buf_p - buffer);
	stream = fopen (filename.fileSystemRepresentation,"w");
	if (!stream)
	{
		NSRunAlertPanel(@"ERROR!",
			@"Can't open %@! Someone must be messing with it!",
			@"OK", nil, nil, filename);
		free(buffer);
		return;
	}

	fwrite (buffer, size, 1, stream);
	fclose (stream);
	printf ("%s:  %i bytes\n", filename.UTF8String, size);

	free (buffer);
}


/*
================
=
= writePatchNames
=
================
*/

- writePatchNames
{
	int	count, i,j;
	worldtexture_t	*tex;
	int	lump;
	char	string[1024];
	
	buffer = [self getBuffer];
//
// write out names of wall patches used
//
	count = 0;
	buf_p = buffer + 4;
	memset (lumptopatchnum, -1, sizeof(lumptopatchnum));
	
	for (i= 0 ; i<numtextures ; i++)
	{
		tex = &textures[i];
		for (j=0 ; j<tex->patchcount ; j++)
		{
			lump = [wadfile_i lumpNamed: tex->patches[j].patchname];
			if (lumptopatchnum[lump] == -1)
			{
				memcpy (buf_p, tex->patches[j].patchname,8);
				buf_p += 8;
				lumptopatchnum[lump] = count;
				count++;
			}
		}
	}
		
	*(int *)buffer = LongSwap (count);
	sprintf(string,"%s/pnames.lmp",mapwads);
	[self writeBuffer: @(string)];

	return self;
}



/*
===============
=
= writeDoomTextures
=
= Writes out a textures.lmp file with the doom version of all the textures
=
===============
*/

- writeDoomTextures
{
	mappatch_t	*patch;
	maptexture_t	*tex;
	worldtexture_t	*wtex;
	worldpatch_t	*wpatch;
	int			*list_p;
	int			i,j;
	
	int			max, windex;
	char			txtrname[1024];

	//
	//	Find out how many sets of textures there are
	//
	max = 0;
	for (i = 0; i < numtextures; i++)
		if (textures[i].WADindex > max )
			max = textures[i].WADindex;
			
	for (windex = 0; windex <= max; windex++)
	{
		int		nt;
		
		[self getBuffer];
	
		//
		//	Leave space for an index table
		//
		for (nt = 0,i = 0;i < numtextures;i++)
			if (textures[i].WADindex == windex)
				nt++;
		
		*(int *)buffer = LongSwap (nt);
		list_p = (int *)(buffer + 4);
		buf_p = buffer + (nt+1)*4;
	
		//
		// write out textures used
		//	
		for (i=0 ; i<numtextures ; i++)
		{
			wtex = &textures[i];
			if (wtex->WADindex != windex )
				continue;
	
			*list_p++ = LongSwap ((unsigned)(buf_p-buffer));
			tex = (maptexture_t *)buf_p;
			buf_p += sizeof(*tex) - sizeof(tex->patches);
			
			strncpy(tex->name,wtex->name,8);   // JR 4/5/93
			tex->masked = NO;
			tex->width = ShortSwap (wtex->width);
			tex->height = ShortSwap (wtex->height);
			tex->collumndirectory = NULL;
			tex->patchcount = ShortSwap(wtex->patchcount);
			for (j=0 ; j<wtex->patchcount ; j++)
			{
				wpatch = &wtex->patches[j];
				patch = (mappatch_t *)buf_p;
				buf_p += sizeof(mappatch_t);
				
				patch->originx = ShortSwap(wpatch->originx);
				patch->originy = ShortSwap(wpatch->originy);
				patch->patch = ShortSwap( 
					lumptopatchnum [ [wadfile_i lumpNamed: wpatch->patchname]  ]  );
				patch->stepdir = ShortSwap(wpatch->stepdir);
				patch->colormap = ShortSwap(wpatch->colormap);
			}	
		}
		
		
		//
		// write it out to disk
		//
		sprintf( txtrname, "%s/texture%d.lmp", mapwads,windex+1 );
		[self writeBuffer: @(txtrname)];
	}

	return self;
}

/*
===============
=
= saveDoomLumps
=
= Writes out textures.lmp file with the doom version of all the textures
=
===============
*/

- (void)saveDoomLumps
{
	chdir (mapwads);
	[self writePatchNames];
	[self writeDoomTextures];
}

//====================================================
//
//	Initialize and display the thermometer
//
//====================================================
- (void)initThermo:(NSString *)title message:(NSString *)msg
{
	[thermoTitle_i	setStringValue:title];
	[thermoMsg_i	setStringValue:msg];
	[thermoView_i	setThermoWidth:0 max:1000];
	[thermoView_i	setNeedsDisplay:YES];
	[thermoWindow_i	makeKeyAndOrderFront:NULL];
	NXPing();
}

//====================================================
//
//	Update the thermometer
//
//====================================================
- (void)updateThermo:(int)current max:(int)maximum
{
	[thermoView_i	setThermoWidth:current	max:maximum];
	[thermoView_i	setNeedsDisplay:YES];
}

//====================================================
//
//	Toast the thermometer
//
//====================================================
- (void)closeThermo
{
	[thermoWindow_i	orderOut:self];
}

@end

/*
================
=
= IO_Error
=
================
*/

void IO_Error (char *error, ...)
{
	va_list	argptr;
	NSString *objcString;

	va_start (argptr,error);
	objcString = [[NSString alloc] initWithFormat:@(error) arguments:argptr];
	va_end (argptr);


	NSRunAlertPanel(@"Error", @"%@", nil, nil, nil, objcString);
	[objcString release];
	[[NSApplication sharedApplication] terminate: nil];
}

//=======================================================
//
//	Draw a red outline (must already be lockFocus'ed on something)
//
//=======================================================
void DE_DrawOutline(NSRect *r)
{
	[[NSColor colorWithDeviceRed:148.0/255 green:0 blue:0 alpha:1] set];
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:r->origin];
	path.lineWidth = 2;
	[path lineToPoint:NSMakePoint(r->origin.x+r->size.width-1,r->origin.y)];
	[path lineToPoint:NSMakePoint(r->origin.x+r->size.width-1,
								  r->origin.y+r->size.height-1)];
	[path lineToPoint:NSMakePoint(r->origin.x,r->origin.y+r->size.height-1)];
	[path lineToPoint:r->origin];
	[path stroke];

	return;	
}

