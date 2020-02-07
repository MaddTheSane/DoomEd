// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

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

#ifdef REDOOMED
#   import <fcntl.h>
#   import <sys/file.h>
#   import <sys/stat.h>
#   import <unistd.h>
#   import "../RDEMapExport.h"
#endif

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


#ifdef REDOOMED
@interface DoomProject (RDEUtilities)
- (BOOL) rdePromptUserForWADfileLocation;
- (BOOL) rdePromptUserForPNGExport;
@end

static bool RDE_FileMatchStringAndGetString(FILE *stream, const char *matchStr,
                                            char *returnedStr, int maxReturnedStrLength);
#endif

@implementation DoomProject


/*
=============================================================================

						PROJECT METHODS

=============================================================================
*/


- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	loaded = NO;
	doomproject_i = self;
	window_i = NULL;
	numtextures = 0;
	texturessize = BASELISTSIZE;
	textures = malloc (texturessize*sizeof(worldtexture_t));
	log_i = [[TextLog	alloc] initWithTitle:@"DoomEd Error Log" ];
	projectdirty = mapdirty = FALSE;
	
	return self;
}

- (void)checkDirtyProject
{
	NSInteger	val;
	
#ifdef REDOOMED
	// don't display a save prompt if there's no project loaded
	if (!loaded)
		return;
#endif

	if ([self	projectDirty] == FALSE)
		return;
		
	val = NXRunAlertPanel("Important",
		"Do you wish to save your project before exiting?",
		"Yes", "No",NULL);
	if (val == NX_ALERTDEFAULT)
		[self	saveProject:self];
}

//
//	App is going to terminate:
//
- quit
{
	[editworld_i	closeWorld];
	[self	checkDirtyProject];
	
	return self;
}

- setDirtyProject:(BOOL)truth
{
	self.projectDirty = truth;
	return self;
}

- setDirtyMap:(BOOL)truth
{
	self.mapDirty = truth;
	return self;
}

@synthesize mapDirty=mapdirty;
@synthesize projectDirty=projectdirty;

- (void)setMapDirty:(BOOL)mapDirty
{
	mapdirty = mapDirty;
	[[editworld_i getMainWindow] setDocumentEdited:mapDirty];
}

- (IBAction)displayLog:sender
{
	[log_i	display:NULL];
}

@synthesize loaded;

- (char *)wadfile
{
	return wadfile;
}


- (char const *)directory
{
	return projectdirectory;
}

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
	
#ifdef REDOOMED
	// use RDE_FileMatchStringAndGetString() instead of fscanf():
	// prevents buffer overflows, can read filepaths containing spaces, & reads empty filepaths
	if (!RDE_FileMatchStringAndGetString(stream, "wadfile: ", wadfile, RDE_MAX_FILEPATH_LENGTH))
		return NO;

	if (!RDE_FileMatchStringAndGetString(stream, "mapwads: ", mapwads, RDE_MAX_FILEPATH_LENGTH))
		return NO;

	// for safety, don't allow the project file (which may have come from an external source)
	// to determine the path of an output directory (mapwads) - instead, force the map wads
	// (& lump files) to save into the project's directory
	strcpy(mapwads, projectdirectory);

	if (!RDE_FileMatchStringAndGetString(stream, "BSPprogram: ", bspprogram,
	                                        RDE_MAX_FILEPATH_LENGTH))
	{
		return NO;
	}

	if (!RDE_FileMatchStringAndGetString(stream, "BSPhost: ", bsphost, sizeof(bsphost) - 1))
		return NO;
#else // Original
	if (fscanf (stream, "\nwadfile: %s\n",wadfile) != 1)
		return NO;
	
	if (fscanf (stream, "mapwads: %s\n",mapwads) != 1)
		return NO;
	
	if (fscanf (stream, "BSPprogram: %s\n",bspprogram) != 1)
		return NO;
	
	if (fscanf (stream, "BSPhost: %s\n",bsphost) != 1)
		return NO;
#endif
	
	if (fscanf(stream,"nummaps: %d\n", &nummaps) != 1)
		return NO;
		
	for (i=0 ; i<nummaps ; i++)
#ifdef REDOOMED
		// prevent buffer overflows: specify string buffer sizes in *scanf() format strings
		if (fscanf(stream,"%8s\n", mapnames[i]) != 1)
			return NO;
#else // Original
		if (fscanf(stream,"%s\n", mapnames[i]) != 1)
			return NO;
#endif

	return YES;
}

/*
===============
=
= savePV1File:
=
===============
*/

- (void)savePV1File: (FILE *)stream
{
	int	i;

	fprintf (stream, "\nwadfile: %s\n",wadfile);
	fprintf (stream, "mapwads: %s\n",mapwads);
	fprintf (stream, "BSPprogram: %s\n",bspprogram);
	fprintf (stream, "BSPhost: %s\n",bsphost);
	fprintf (stream,"nummaps: %d\n", nummaps);
		
	for (i=0 ; i<nummaps ; i++)
		fprintf (stream,"%s\n", mapnames[i]);
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
		NXRunAlertPanel ("Error","No project loaded",NULL,NULL,NULL);
		return;
	}
	
	if (!window_i)
	{
		[NXApp 
			loadNibSection:	"Project.nib"
			owner:			self
			withNames:		NO
		];
		[window_i	setFrameUsingName:DOOMNAME];
		
	}

	[self updatePanel];
	[window_i orderFront:self];
}

- (void)saveFrame
{
	if (window_i)
		[window_i	saveFrameUsingName:DOOMNAME];
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
	NSOpenPanel	*openpanel;
#ifdef REDOOMED
	// Cocoa compatibility: -[NSOpenPanel runModalForTypes:] takes an NSArray
	NSArray *suffixlist = [NSArray arrayWithObject: @"dpr"];
#else // Original
	static char	*suffixlist[] = {"dpr", 0};
#endif

	[self	checkDirtyProject];
	
	openpanel = [NSOpenPanel new];

#ifdef REDOOMED
	// prevent memory leaks
	[openpanel autorelease];
#endif

	[openpanel setAllowedFileTypes:suffixlist];
	if (![openpanel runModal] )
		return;

	printf("Purging existing texture patches.\n");
	[ textureEdit_i	dumpAllPatches ];	
	
	printf("Purging existing flats.\n");
	[ sectorEdit_i	dumpAllFlats ];
	
	if (![self loadProjectWithFileURL: [openpanel URL]])
	{
		NXRunAlertPanel("Uh oh!","Couldn't load your project!",
			"OK",NULL,NULL);

#ifdef REDOOMED
		// after the failed call to loadProject:, the DoomProject's members are in an unknown
		// state, so rather than crashing while trying to reload the old project's resources,
		// just exit gracefully...
		[NSApp terminate: self];
#else // Original
		[ wadfile_i	initFromFile: wadfile ];
		[ textureEdit_i		initPatches ];
		[ sectorEdit_i		loadFlats ];
		[ thingPalette_i	initIcons];
		[ wadfile_i	close ];
#endif
		
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
	FILE		*stream;
	NSOpenPanel	*panel;
#ifdef REDOOMED
	NSString    *filename;
	NSArray     *fileTypes = [NSArray arrayWithObject: @"wad"];
	BOOL        isDirectory;
#else // Original
	char		const *filename;
	static char *fileTypes[] = { "wad",NULL};
#endif
	char		projpath[1024];
	char		texturepath[1024];


	[self	checkDirtyProject];
	//
	// get directory for project & files
	//	
	panel = [NSOpenPanel new];

#ifdef REDOOMED
	// prevent memory leaks
	[panel autorelease];

	// enable the open panel's 'new folder' button
	[panel setCanCreateDirectories: YES];

	[panel setTitle: @"Project directory"];
#else // Original
	[panel setTitle: "Project directory"];
#endif

	[panel setCanChooseDirectories:YES];
	if (! [panel runModal] )
		return;
		
	filename = [panel filename];

#ifdef REDOOMED
	if (!filename
	    || ![[NSFileManager defaultManager] fileExistsAtPath: filename
		                                    isDirectory: &isDirectory]
		|| !isDirectory)
#else // Original
	if (!filename || !*filename)
#endif
	{
		NXRunAlertPanel("Nope.","I need a directory for projects to"
			" create one.","OK",NULL,NULL);
		return;
	}
		
#ifdef REDOOMED
	if ([filename length] > RDE_MAX_FILEPATH_LENGTH)
	{
		NXRunAlertPanel("Nope.","Project directory path is too long.","OK",NULL,NULL);
		return;
	}

	strcpy (projectdirectory, RDE_CStringFromNSString(filename));
#else // Original
	strcpy (projectdirectory, filename);
#endif
	
	//
	// get wadfile
	//
#ifdef REDOOMED
	[panel setTitle: @"Wadfile"];
#else // Original
	[panel setTitle: "Wadfile"];
#endif

	[panel setCanChooseDirectories:NO];
	[panel setAllowedFileTypes:fileTypes];
	if (! [panel runModal] )
		return;
		
	filename = [panel filename];

#ifdef REDOOMED
	if (!filename
        || ![[NSFileManager defaultManager] fileExistsAtPath: filename])
#else // Original
	if (!filename || !*filename)
#endif
	{
		NXRunAlertPanel("Nope.","I need a WADfile for this project.",
			"OK",NULL,NULL);
		return;
	}
		
#ifdef REDOOMED
	if ([filename length] > RDE_MAX_FILEPATH_LENGTH)
	{
		NXRunAlertPanel("Nope.","WADfile path is too long.","OK",NULL,NULL);
		return;
	}

	strcpy (wadfile, RDE_CStringFromNSString(filename));
#else // Original
	strcpy (wadfile, filename);
#endif
		
	//
	// create default data: project file
	//
	nummaps = 0;
	numtextures = 0;
	
	strcpy (projpath, projectdirectory);
	strcat (projpath, "/project.dpr");

	printf("Creating a new project: %s\n", projectdirectory );
	stream = fopen (projpath,"w+");
	if (!stream)
	{
		NXRunAlertPanel ("Error","Couldn't create %s.",
			NULL,NULL,NULL, projpath);
		return;
	}
	fprintf (stream, "Doom Project version 1\n\n");
	fprintf (stream, "wadfile: %s\n\n",wadfile);
	fprintf (stream,"nummaps: 0\n");
	fclose (stream);

	strcpy(texturepath,projectdirectory);
	strcat(texturepath,"/texture1.dsp");
	stream = fopen (texturepath,"w+");
	if (!stream)
	{
		NXRunAlertPanel ("Error","Couldn't create %s.",
			NULL,NULL,NULL,texturepath);
		return;
	}
	fprintf (stream, "numtextures: 0\n");
	fclose (stream);
	
#ifdef REDOOMED
	// Bugfix: don't leave mapwads as an empty string, otherwise the app will try saving map
	// wads & lump files to the system's root directory; force those files to save into the
	// project's directory
	strcpy(mapwads, projectdirectory);
#endif

	//
	// load in and init all the WAD patches
	//
	loaded = YES;
	
	if ( !wadfile_i )
		wadfile_i = [[ Wadfile alloc ] init];

	[editworld_i	closeWorld];

	[sectorEdit_i	emptySpecialList];
	[linepanel_i	emptySpecialList];
	[thingpanel_i	emptyThingList];

	printf("Initializing WADfile %s\n",wadfile);
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
	
	[self setMapDirty:FALSE];
	[self setProjectDirty:FALSE];
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
	char		filename[1024];

	if (!loaded)
		return;
		
	strcpy (filename, projectdirectory);
	strcat (filename ,"/project.dpr");
	stream = fopen (filename,"w");
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
	[self setProjectDirty:FALSE];
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
#ifdef REDOOMED
	[projectpath_i setStringValue: RDE_NSStringFromCString(projectdirectory)];
	[wadpath_i setStringValue: RDE_NSStringFromCString(wadfile)];
	[BSPprogram_i	setStringValue: RDE_NSStringFromCString(bspprogram)];
	[BSPhost_i		setStringValue: RDE_NSStringFromCString(bsphost)];
	[mapwaddir_i	setStringValue: RDE_NSStringFromCString(mapwads)];
#else // Original
	[projectpath_i setStringValue: projectdirectory];
	[wadpath_i setStringValue: wadfile];
	[BSPprogram_i	setStringValue: bspprogram];
	[BSPhost_i		setStringValue: bsphost];
	[mapwaddir_i	setStringValue: mapwads];
#endif

	[maps_i reloadColumn: 0];	
}

- changeWADfile:(char *)string
{
	strcpy(wadfile,string);
	[self	updatePanel];
	NXRunAlertPanel("Note!", "The WADfile will be changed when you\n"
		"restart DoomEd.  Make sure you SAVE YOUR PROJECT!",
		"OK",NULL,NULL);
	return self;
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

- loadProject: (char const *)path
{
	if ([self loadProjectWithFileURL:[NSURL fileURLWithFileSystemRepresentation:path isDirectory:NO relativeToURL:nil]]) {
		return self;
	}
	return nil;
}
- (BOOL)loadProjectWithFileURL:(NSURL *)path;
{
	FILE	*stream;
	char	projpath[1024];
	int		version, ret;
	int		oldnumtextures;
#ifdef REDOOMED
	BOOL    didChangeWADfilepath = NO;

	if (strlen(path.fileSystemRepresentation) > RDE_MAX_FILEPATH_LENGTH)
	{
		NXRunAlertPanel ("Error","%s","OK",NULL,NULL, "Project filepath is too long.");
		return NO;
	}
#endif
	
	strcpy (projectdirectory, path.fileSystemRepresentation);
	StripFilename (projectdirectory);
	
	strcpy (projpath, projectdirectory);
	strcat (projpath, "/project.dpr");
	
	stream = fopen (projpath,"r");
	if (!stream)
	{
		NXRunAlertPanel ("Error","Couldn't open %s",NULL,NULL,NULL, projpath);
		return NO;
	}
	version = -1;
	fscanf (stream, "Doom Project version %d\n", &version);
	if (version == 1)
		ret = [self loadPV1File: stream];
	else
	{
		fclose (stream);
		NXRunAlertPanel ("Error","Unknown file version for project %s",
			NULL,NULL,NULL, projpath);
		return NO;
	}

	if (!ret)
	{
		fclose (stream);
		NXRunAlertPanel ("Error","Couldn't parse project file %s",NULL,NULL,NULL, projpath);
		return NO;
	}
	
	fclose (stream);
	
	projectdirty = NO;
	texturesdirty = NO;
	loaded = YES;
	oldnumtextures = numtextures;

#ifdef REDOOMED
    // if the project came from a different machine, the project's local wadfile path is
    // probably invalid - if so, let the user manually locate the project's wadfile
    if (![[NSFileManager defaultManager] fileExistsAtPath: RDE_NSStringFromCString(wadfile)])
    {
        didChangeWADfilepath = [self rdePromptUserForWADfileLocation];

        if (!didChangeWADfilepath)
        {
            return NO;
        }
    }
#endif

	wadfile_i = [[Wadfile alloc] initFromFile: wadfile];
	if (!wadfile_i)
	{
		NXRunAlertPanel ("Error","Couldn't open wadfile %s",
			NULL,NULL,NULL, wadfile);
		return NO;
	}
	
	[editworld_i	closeWorld];
	[log_i	addMessage:@"DoomEd initializing...\n\n" ];
	
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

#ifdef REDOOMED
	[self	setProjectDirty:didChangeWADfilepath];
#else // Original
	[self	setDirtyProject:FALSE];
#endif

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

	//return self;
}

//============================================================
//
//	Sort the maps internally
//
//============================================================
- (void)sortMaps
{
	int		i;
	int		j;
	int		flag;
	char	name[16];
	
	flag = 1;
	while(flag)
	{
		flag = 0;
		for(i=0;i<nummaps;i++)
			for(j=i+1;j<nummaps;j++)
				if (strcmp(mapnames[j],mapnames[i])<0)
				{
					strcpy(name,mapnames[i]);
					strcpy(mapnames[i],mapnames[j]);
					strcpy(mapnames[j],name);
					flag = 1;
					break;
				}
	}
}

/*
===============
=
= browser:fillMatrix:inColumn:
=
===============
*/

#ifdef REDOOMED
// Cocoa version
- (void) browser: (NSBrowser *) sender
        createRowsForColumn: (NSInteger) column
        inMatrix: (NSMatrix *) matrix
#else // Original
- (int)browser:sender  fillMatrix:matrix  inColumn:(int)column
#endif
{
	int	i;
	id	cell;

	if (column != 0)
#ifdef REDOOMED
		return; // Cocoa version doesn't return a value
#else // Original
		return 0;
#endif

	[self	sortMaps];
		
	for (i=0 ; i<nummaps ; i++)
	{
		[matrix addRow];
		cell = [matrix cellAtRow: i column: 0];

#ifdef REDOOMED
		[cell setStringValue: RDE_NSStringFromCString(mapnames[i])];
#else // Original
		[cell setStringValue: mapnames[i]];
#endif

		[cell setLeaf: YES];
		[cell setLoaded: YES];
		[cell setEnabled: YES];
	}
	
#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return nummaps;
#endif
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
	FILE		*stream;
	char		pathname[1024];
	char		const	*title;
	int		len, i;

	//
	// get filename for map
	//	
#ifdef REDOOMED
	title = RDE_CStringFromNSString([mapNameField_i stringValue]);
#else // Original
	title = [mapNameField_i stringValue];
#endif

	len = strlen (title);
	if (len < 1 || len > 8)
	{
		NXRunAlertPanel ("Error","Map names must be 1 to 8 characters",
			NULL, NULL, NULL);
		return;
	}
	
	for (i=0 ; i<nummaps ; i++)
		if (!strcmp(title, mapnames[i]))
		{
			NXRunAlertPanel ("Error","Map name in use",NULL, NULL, NULL);
			return;
		}
		
	//
	// write an empty file
	//
	strcpy (pathname, projectdirectory);
	strcat (pathname, "/");
	strcat (pathname,title);
	strcat (pathname,".dwd");
	stream = fopen (pathname,"w");
	if (!stream)
	{
		NXRunAlertPanel ("Error","Could not open %s",
			NULL, NULL, NULL, pathname);
		return;
	}
	fprintf (stream, "WorldServer version 0\n");
	fclose (stream);

//
// add the map and update the browser
//
	strcpy (mapnames[nummaps], title);
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
	id			cell;
	const char	*title;
	char			fullpath[1024];
	char			string[80];

	if ([editworld_i loaded])
		[editworld_i closeWorld];
	
	cell = [sender selectedCell];

#ifdef REDOOMED
	title = RDE_CStringFromNSString([cell stringValue]);
#else // Original
	title = [cell stringValue];
#endif
	
	strcpy (fullpath, projectdirectory);
	strcat (fullpath,"/");
	strcat (fullpath,title);
	strcat (fullpath,".dwd");

	[ log_i	addFormattedMessage:@"\nLoading map %s\n", title];
	[editworld_i loadWorldFile: fullpath];
	
#ifdef REDOOMED
	// EditWorld's changeLine:to: & changeThing:to: methods now set the mapdirty flag, so
	// reset it after opening a map
	[self setMapDirty: FALSE];
#endif
}

//===================================================================
//
//	Load Map Functions
//
//===================================================================
int	oldSelRow,curMap;
NSMatrix *openMatrix;

//	Init to start opening all maps
- beginOpenAllMaps
{
	openMatrix = [maps_i	matrixInColumn:0];
	oldSelRow = [openMatrix	selectedRow];
	curMap = 0;
	return self;
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
#ifdef REDOOMED
	// DoomEd's 'doomprint' command-line tool is currently unimplemented in ReDoomEd -
    // give the option of exporting to PNG instead

    if (loaded
        && [self rdePromptUserForPNGExport])
    {
        [self rdeExportAllMapsAsPNG];
    }

#else // Original
	id		openMatrix;
	int		i;
	int		selRow;

	[editworld_i	closeWorld];

	openMatrix = [maps_i	matrixInColumn:0];
	selRow = [openMatrix	selectedRow];
	
	for (i = 0;i < nummaps; i++)
	{
		[openMatrix	selectCellAt:i :0];
		[self	openMap:openMatrix];
		[self	printMap:NULL];
	}
	
	if (selRow >=0)
	{
		[openMatrix	selectCellAt:selRow :0];
		[self	openMap:openMatrix];
	}

#endif // Original
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
#ifdef REDOOMED
	// DoomEd's 'doomprint' command-line tool is currently unimplemented in ReDoomEd -
    // give the option of exporting to PNG instead

    if (!loaded || ![editworld_i getMainWindow])
    {
        NSBeep();
        return;
    }

    if ([self rdePromptUserForPNGExport])
    {
        [self rdeExportMapAsPNG];
    }

#else // Original
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
		NXBeep();
		return self;
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
		projectdirectory,
		[cell stringValue]);
		
	panel = NXGetAlertPanel("Wait...","Printing %s.",
		NULL,NULL,NULL,[cell stringValue]);
		
	[panel	orderFront:NULL];
	NXPing();
	system(string);
	[panel	orderOut:NULL];
	NXFreeAlertPanel(panel);
	
#endif // Original
}

//===================================================================
//
// 				MAP MUNGE: LOAD AND SAVE ALL MAPS
//
//===================================================================
- (IBAction)loadAndSaveAllMaps:sender
{
	NSMatrix	*openMatrix;
	NSInteger	i;
	NSInteger	selRow;

#if 0
	rv = NXRunAlertPanel("Warning!",
		"This may take awhile!  Make sure your map is saved!",
		"Abort","Continue",NULL,NULL);
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
	NSInteger		i,nt,k;
	int		tset;
	int		*textureCount;
	NSInteger indx;
	FILE		*stream;
	char		filename[]="/tmp/tempstats.txt\0";
	texpal_t	*t;
	NSMatrix	*openMatrix;
	NSInteger	selRow;
	int		numth;
	tc_t	*thingCount;
	
	if ([editworld_i	loaded] == NO)
	{
		NXRunAlertPanel("Hey!",
			"You don't have a world loaded!",
			"Oops, what a dolt I am!",NULL,NULL);
		return;
	}
	
	[ log_i	addMessage:@"Single map statistics\n" ];

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
					NSInteger	index;
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
	nt = [texturePalette_i	countOfTextures];
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
			NXRunAlertPanel("Programming Error?",
							"Returned a bad texture index: %ld",
							"Continue",NULL,NULL,(long)indx);
		
		if (indx >= 0)
			textureCount[indx]++;
		else
		if (indx == -2)
		{
			NXRunAlertPanel("Error!",
				"Found a line with a texture that isn't present: '%s'",
				"Continue",NULL,NULL, lines[k].side[0].bottomtexture);
			[editworld_i	selectLine:k];
			[log_i addFormattedMessage:@"Line %ld: texture '%s' nonexistent!\n", (long)k, lines[k].side[0].bottomtexture];
			return;
		}

		//
		// MIDDLE
		//
		indx = [texturePalette_i
				getTextureIndex:lines[k].side[0].midtexture];
		if (indx >= nt)
			NXRunAlertPanel("Programming Error?",
							"Returned a bad texture index: %ld",
							"Continue",NULL,NULL,(long)indx);
		if (indx >= 0)
			textureCount[indx]++;
		else
		if (indx == NSNotFound)
		{
			NXRunAlertPanel("Error!",
				"Found a line with a texture that isn't present: '%s'",
				"Continue",NULL,NULL, lines[k].side[0].midtexture);
			[editworld_i	selectLine:k];
			[log_i addFormattedMessage:@"Line %ld: texture '%s' nonexistent!\n", (long)k, lines[k].side[0].midtexture];
			return;
		}

		//
		// TOP
		//
		indx = [texturePalette_i
				getTextureIndex:lines[k].side[0].toptexture];
		if (indx >= nt)
			NXRunAlertPanel("Programming Error?",
							"Returned a bad texture index: %ld",
							"Continue",NULL,NULL,(long)indx);
		if (indx >= 0)
			textureCount[indx]++;
		else
		if (indx == NSNotFound)
		{
			NXRunAlertPanel("Error!",
				"Found a line with a texture that isn't present: '%s'",
				"Continue",NULL,NULL, lines[k].side[0].toptexture);
			[editworld_i	selectLine:k];
			[log_i	addFormattedMessage:@"Line %ld: texture '%s' nonexistent!\n", (long)k, lines[k].side[0].toptexture];
			return;
		}

		// SIDE 1
		//
		// BOTTOM
		//
		indx = [texturePalette_i
				getTextureIndex:lines[k].side[1].bottomtexture];
		if (indx >= nt)
			NXRunAlertPanel("Programming Error?",
							"Returned a bad texture index: %ld",
							"Continue",NULL,NULL,(long)indx);
		
		if (indx >= 0)
			textureCount[indx]++;
		else
		if (indx == -2)
		{
			NXRunAlertPanel("Error!",
				"Found a line with a texture that isn't present: '%s'",
				"Continue",NULL,NULL, lines[k].side[1].bottomtexture);
			[editworld_i	selectLine:k];
			[log_i addFormattedMessage:@"Line %ld: texture '%s' nonexistent!\n",
			 (long)k, lines[k].side[0].bottomtexture];
			return;
		}

		//
		// MIDDLE
		//
		indx = [texturePalette_i
				getTextureIndex:lines[k].side[1].midtexture];
		if (indx >= nt)
			NXRunAlertPanel("Programming Error?",
							"Returned a bad texture index: %ld",
							"Continue",NULL,NULL,(long)indx);
		if (indx >= 0)
			textureCount[indx]++;
		else
		if (indx == -2)
		{
			NXRunAlertPanel("Error!",
				"Found a line with a texture that isn't present: '%s'",
				"Continue",NULL,NULL,lines[k].side[1].midtexture);
			[editworld_i	selectLine:k];
			[log_i addFormattedMessage:@"Line %ld: texture '%s' nonexistent!\n", (long)k, lines[k].side[0].midtexture];
			return;
		}

		//
		// TOP
		//
		indx = [texturePalette_i
				getTextureIndex:lines[k].side[1].toptexture];
		if (indx >= nt)
			NXRunAlertPanel("Programming Error?",
							"Returned a bad texture index: %ld",
							"Continue",NULL,NULL,(long)indx);
		if (indx >= 0)
			textureCount[indx]++;
		else
		if (indx == NSNotFound)
		{
			NXRunAlertPanel("Error!",
				"Found a line with a texture that isn't present: '%s'",
				"Continue",NULL,NULL, lines[k].side[1].toptexture);
			[editworld_i	selectLine:k];
			[log_i addFormattedMessage:@"Line %ld: texture '%s' nonexistent!\n", (long)k, lines[k].side[0].toptexture];
			return;
		}
	}
		
	//
	// create stats file
	//
	openMatrix = [maps_i matrixInColumn:0];
	selRow = [openMatrix	selectedRow];

	stream = fopen (filename,"w");
	fprintf(stream,"DoomEd Map Statistics for %s\n\n",
#ifdef REDOOMED
			RDE_CStringFromNSString([[openMatrix cellAtRow:selRow column:0] stringValue]));
#else // Original
		[[openMatrix cellAt:selRow :0] stringValue]);
#endif

	fprintf(stream,"Texture count:\n");
	tset = -1;
	for (i=0;i<nt;i++)
	{
		if (!textureCount[i])
			continue;
		t = [texturePalette_i	getTexture:(int)i];
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
#ifdef REDOOMED
	[[NSWorkspace sharedWorkspace]	openTempFile:RDE_NSStringFromCString(filename)];
#else // Original
	[[Application	workspace]	openTempFile:filename];
#endif
	
	free(textureCount);
}

//===================================================================
//
// 							PRINT ALL MAP STATISTICS
//
//===================================================================
- (IBAction)printStatistics:sender
{
	NSMatrix *openMatrix;

	int		numPatches;
	int		*patchCount;
	const char *patchName;
	
	int		i;
	int		k;
	int		j;
	NSInteger nt;
	NSInteger selRow;
	NSInteger nf;
	NSInteger flat;
	int		errors;
	int		*textureCount, *flatCount;
	NSInteger indx;
	FILE	*stream;
	char	filename[]="/tmp/tempstats.txt\0";
	texpal_t	*t;
	int		numth;
	tc_t	*thingCount;
	id		thingList_i;
	
#if 0
	rv = NXRunAlertPanel("Warning!",
		"This may take awhile!  Make sure your map is saved!",
		"Abort","Continue",NULL,NULL);
	if (rv == 1)
		return self;
#endif
	[editworld_i	closeWorld];

	openMatrix = [maps_i	matrixInColumn:0];
	selRow = [openMatrix	selectedRow];
	
	nt = [texturePalette_i	countOfTextures];
	textureCount = malloc(sizeof(int) * nt);
	bzero(textureCount,sizeof(int)*nt);
	
	nf = [sectorEdit_i	countOfFlats];
	flatCount = malloc ( sizeof(*flatCount) * nf );
	bzero (flatCount, sizeof (*flatCount) * nf );

	thingList_i = [thingPanel_i thingList];
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
	
	[log_i addMessage:@"Starting to calculate multiple map statistics...\n"];
	
	errors = 0;
	
	for (i = 0;i < nummaps; i++)
	{
		[log_i addFormattedMessage:@"Loading map %@.\n", [[openMatrix selectedCell] stringValue]];
		[openMatrix	selectCellAtRow:i column:0];
		[self	openMap:openMatrix];
		
		//
		//	Thing report data
		//
		[log_i	addMessage:@"Counting things.\n" ];
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
						NSInteger	index;
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
		[log_i	addMessage:@"Counting textures and flats.\n" ];
		for (k=0;k<numlines;k++)
		{
			// SIDE 0
			indx = [texturePalette_i
					getTextureIndex:lines[k].side[0].bottomtexture];

			if (indx >= nt)
				NXRunAlertPanel("Programming Error?",
								"Returned a bad texture index: %ld",
								"Continue",NULL,NULL,(long)indx);
			
			if (indx >= 0)
				textureCount[indx]++;
			else
			if (indx == -2)
			{
				[textureRemapper_i
					addToList:lines[k].side[0].bottomtexture to:"???"];
				errors++;
			}

			indx = [texturePalette_i
					getTextureIndex:lines[k].side[0].midtexture];
			if (indx >= nt)
				NXRunAlertPanel("Programming Error?",
								"Returned a bad texture index: %ld",
								"Continue",NULL,NULL,(long)indx);
			if (indx >= 0)
				textureCount[indx]++;
			else
			if (indx == -2)
			{
				[textureRemapper_i
					addToList:lines[k].side[0].midtexture to:"???"];
				errors++;
			}

			indx = [texturePalette_i
					getTextureIndex:lines[k].side[0].toptexture];
			if (indx >= nt)
				NXRunAlertPanel("Programming Error?",
								"Returned a bad texture index: %ld",
								"Continue",NULL,NULL,(long)indx);
			if (indx >= 0)
				textureCount[indx]++;
			else
			if (indx == -2)
			{
				[textureRemapper_i
					addToList:lines[k].side[0].toptexture to:"???"];
				errors++;
			}
			
			if (lines[k].side[0].ends.floorflat[0])
			{
				flat = [sectorEdit_i
					findFlat:lines[k].side[0].ends.floorflat ];
				if (flat != NSNotFound)
					flatCount[flat]++;
				else
				{
					[flatRemapper_i
						addToList:lines[k].side[0].ends.floorflat  to:"???"];
					errors++;
				}
			}
			if (lines[k].side[0].ends.ceilingflat[0])
			{
				flat = [ sectorEdit_i
					findFlat:lines[k].side[0].ends.ceilingflat ];
				if (flat != NSNotFound)
					flatCount[flat]++;
				else
				{
					[flatRemapper_i
						addToList:lines[k].side[0].ends.ceilingflat  to:"???"];
					errors++;
				}
			}

			// SIDE 1
			indx = [texturePalette_i
					getTextureIndex:lines[k].side[1].bottomtexture];
			if (indx >= nt)
				NXRunAlertPanel("Programming Error?",
								"Returned a bad texture index: %ld",
								"Continue",NULL,NULL,(long)indx);
			
			if (indx >= 0)
				textureCount[indx]++;
			else
			if (indx == -2)
			{
				[textureRemapper_i
					addToList:lines[k].side[1].bottomtexture to:"???"];
				errors++;
			}

			indx = [texturePalette_i
					getTextureIndex:lines[k].side[1].midtexture];
			if (indx >= nt)
				NXRunAlertPanel("Programming Error?",
								"Returned a bad texture index: %ld",
								"Continue",NULL,NULL,(long)indx);
			if (indx >= 0)
				textureCount[indx]++;
			else
			if (indx == -2)
			{
				[textureRemapper_i
					addToList:lines[k].side[1].midtexture to:"???"];
				errors++;
			}

			indx = [texturePalette_i
					getTextureIndex:lines[k].side[1].toptexture];
			if (indx >= nt)
				NXRunAlertPanel("Programming Error?",
								"Returned a bad texture index: %ld",
								"Continue",NULL,NULL,(long)indx);
			if (indx >= 0)
				textureCount[indx]++;
			else
			if (indx == -2)
			{
				[textureRemapper_i
					addToList:lines[k].side[1].toptexture to:"???"];
				errors++;
			}

			if (lines[k].side[1].ends.floorflat[0])
			{
				flat = [ sectorEdit_i
					findFlat:lines[k].side[1].ends.floorflat ];
				if (flat >= 0)
					flatCount[flat]++;
				else
				{
					[flatRemapper_i
						addToList:lines[k].side[1].ends.floorflat  to:"???"];
					errors++;
				}
			}
			
			if (lines[k].side[1].ends.ceilingflat[0])
			{
				flat = [ sectorEdit_i
						findFlat:lines[k].side[1].ends.ceilingflat ];
				if (flat >= 0)
					flatCount[flat]++;
				else
				{
					[flatRemapper_i
						addToList:lines[k].side[1].ends.ceilingflat  to:"???"];
					errors++;
				}
			}
		}
	}
	
	if (errors)
		NXRunAlertPanel("Errors!",
			"Found %d lines with textures or flats that aren't present.\n"
			"The Texture/Flat Remappers have these errors listed so you\n"
			"can fix them.",
			"Continue",NULL,NULL, errors);

	//
	// 	Create Stats file
	//
	stream = fopen (filename,"w");
	fprintf(stream,"DoomEd Map Statistics\n\n");

	fprintf(stream,"Number of textures in project:%ld\n",(long)nt);
	fprintf(stream,"Texture count:\n");
	for (i=0;i<nt;i++)
	{
		t = [texturePalette_i	getTexture:i];
		fprintf(stream,"Texture\x9\x9%d\x9\x9\x9%s\n",textureCount[i],t->name);
	}
	
	//
	//	Count flat usage
	//
	fprintf( stream, "Number of flats in project:%ld\n",(long)nf );
	fprintf( stream, "Flat count:\n" );
	for (i = 0; i < nf; i++)
		fprintf( stream, "Flat\x9\x9%d\x9\x9\x9%s\n",flatCount[i],
			[sectorEdit_i flatName:i] );
	
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
	[log_i	addMessage:@"Calculating patch usage: " ];
	numPatches = [textureEdit_i	countOfPatches];
	patchCount = malloc(sizeof(*patchCount) * numPatches);
	bzero(patchCount,sizeof(*patchCount)* numPatches);
	
	fprintf(stream, "Number of patches in project:%d\n",numPatches);
	fprintf(stream, "Patch count:\n");
	for (i = 0;i < numPatches; i++)
	{
		[log_i	addMessage:@"." ];
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
	[log_i	addMessage:@"\nFinished!\n\n" ];
	
	//
	// launch Edit with file!
	//
#ifdef REDOOMED
	[[NSWorkspace sharedWorkspace] openTempFile:RDE_NSStringFromCString(filename)];
#else // Original
	[[Application	workspace]	openTempFile:filename];
#endif
	
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
- updateThings
{
	FILE		*stream;
	char		filename[1024];
	int		handle;

	strcpy (filename, projectdirectory);
	strcat (filename ,"/things.dsp");
	
	handle = open (filename, O_CREAT | O_RDWR, 0666);
	if (handle == -1)
	{
		NXRunAlertPanel ("Error","Couldn't open %s",
			NULL,NULL,NULL, filename);
		return self;
	}		

	flock (handle, LOCK_EX);
	
	stream = fdopen (handle,"r+");
	if (!stream)
	{
		fclose (stream);
		NXRunAlertPanel ("Error","Could not stream to %s",
			NULL,NULL,NULL, filename);
		return self;
	}
	
	printf("Updating things file\n");
	[thingPanel_i	updateThingsDSP:stream];
	flock(handle,LOCK_UN);
	fclose(stream);
	
	return self;
}

//======================================================================
//
//	SPECIAL METHODS
//
//======================================================================
- updateSectorSpecials
{
	FILE		*stream;
	char		filename[1024];
	int		handle;

	strcpy (filename, projectdirectory);
	strcat (filename ,"/sectorspecials.dsp");
	
	handle = open (filename, O_CREAT | O_RDWR, 0666);
	if (handle == -1)
	{
		NXRunAlertPanel ("Error","Couldn't open %s",
			NULL,NULL,NULL, filename);
		return self;
	}		

	flock (handle, LOCK_EX);
	
	stream = fdopen (handle,"r+");
	if (!stream)
	{
		fclose (stream);
		NXRunAlertPanel ("Error","Could not stream to %s",
			NULL,NULL,NULL, filename);
		return self;
	}
	
	printf("Updating Sector Specials file\n");
	[sectorEdit_i	updateSectorSpecialsDSP:stream];
	flock(handle,LOCK_UN);
	fclose(stream);
	
	return self;
}

- updateLineSpecials
{
	FILE		*stream;
	char		filename[1024];
	int		handle;

	strcpy (filename, projectdirectory);
	strcat (filename ,"/linespecials.dsp");
	
	handle = open (filename, O_CREAT | O_RDWR, 0666);
	if (handle == -1)
	{
		NXRunAlertPanel ("Error","Couldn't open %s",
			NULL,NULL,NULL, filename);
		return self;
	}		

	flock (handle, LOCK_EX);
	
	stream = fdopen (handle,"r+");
	if (!stream)
	{
		fclose (stream);
		NXRunAlertPanel ("Error","Could not stream to %s",
			NULL,NULL,NULL, filename);
		return self;
	}
	
	printf("Updating Line Specials file\n");
	[linepanel_i	updateLineSpecialsDSP:stream];
	flock(handle,LOCK_UN);
	fclose(stream);
	
	return self;
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
	int		x;
	int		y;
	int		found;
	Storage		*store;
	worldtexture_t	*t;
	worldtexture_t	*t2;
	worldtexture_t	m;
	worldtexture_t	m2;
	NSInteger		max;
	int		windex;
	NSMutableArray<Storage*>	*list;
	
	printf("Alphabetize textures.\n");
	printf("numtextures = %d\n",numtextures);

#ifdef REDOOMED
	// add missing init call, & autorelease to prevent memory leaks
	list = [[[NSMutableArray alloc] init] autorelease];
#else // Original
	list = [List alloc];
#endif
	
	for (windex = 0; windex <= sets; windex++)
	{
		store = [[Storage alloc]
				initCount:		0
				elementSize:	sizeof(worldtexture_t)
				description:	NULL];

#ifdef REDOOMED
		// prevent memory leaks
		[store autorelease];
#endif
		
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
		
		[list	addObject:store];

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
		store = [list	objectAtIndex:x];
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

#ifdef REDOOMED
	// prevent buffer overflows: specify string buffer sizes in *scanf() format strings
	if (fscanf (file,"%8s %d, %d, %d\n",
#else // Original
	if (fscanf (file,"%s %d, %d, %d\n",
#endif
		tex->name, &tex->width, &tex->height, &tex->patchcount) != 4)
		return NO;
		
	for (i=0 ; i<tex->patchcount ; i++)
	{
		patch = &tex->patches[i];

#ifdef REDOOMED
		// prevent buffer overflows: specify string buffer sizes in *scanf() format strings
		if (fscanf (file,"   (%d, %d : %8s ) %d, %d\n",
#else // Original
		if (fscanf (file,"   (%d, %d : %s ) %d, %d\n",
#endif
			&patch->originx, &patch->originy,
			patch->patchname, &patch->stepdir, &patch->colormap) != 5)
			return NO;
	}

	return YES;
}

- writeTexture: (worldtexture_t *)tex to: (FILE *)file
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

	return self;
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

- (int)textureNamed: (char const *)name
{
	int	i;
	
	if (!strlen(name) || !strcmp (name, "-") )
		return -1;		// no texture
		
	for (i=0 ; i<numtextures ; i++)
		if (!strcasecmp(textures[i].name, name) )
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

- updateTextures
{
	FILE	*stream;
	int		handle;
	char	filename[1024];
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
		panel = NXGetAlertPanel("Wait...",
			"Reading textures from texture%d.dsp.",NULL,NULL,NULL,windex+1);
		[panel	orderFront:NULL];
		NXPing();
		
		sprintf (filename, "%s/texture%d.dsp",projectdirectory,windex+1 );
		
		chmod (filename,0666);
		handle = open (filename,O_RDWR, 0666);
		if (handle == -1)
		{
			if (!windex)
			{
				[panel	orderOut:NULL];
				NXFreeAlertPanel(panel);
				NXPing();
				NXRunAlertPanel ("Error","Couldn't open %s",
					NULL,NULL,NULL, filename);
				return self;
			}
			else
			{
				[panel	orderOut:NULL];
				NXFreeAlertPanel(panel);
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
			NXFreeAlertPanel(panel);
			NXPing();
			NXRunAlertPanel ("Error","Could not stream to %s",
				NULL,NULL,NULL, filename);
			return self;
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
					NXFreeAlertPanel(panel);
					NXPing();
					NXRunAlertPanel ("Error",
						"Could not parse %s",NULL,NULL,NULL, filename);
					return self;
				}

				//
				// if the name is present but not modified, update it
				//	...to the current value
				// if the name is present and modified, don't update it
				// if the name is not present, add it
				//
				num = [self textureNamed:tex.name];
				if (num == -2)
				{
					[self newTexture: &tex];
					num = [self	textureNamed:tex.name ];
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
		NXFreeAlertPanel(panel);
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
		panel = NXGetAlertPanel("Wait...",
			"Writing textures to texture%d.dsp.",NULL,NULL,NULL,windex+1);
		[panel	orderFront:NULL];
		NXPing();
		
		sprintf (filename, "%s/texture%d.dsp",projectdirectory,windex+1 );
		
		BackupFile(filename);
		unlink(filename);
		handle = open (filename,O_CREAT | O_RDWR, 0666);
		if (handle == -1)
		{
			if (!windex)
			{
				[panel	orderOut:NULL];
				NXFreeAlertPanel(panel);
				NXPing();
				NXRunAlertPanel ("Error","Couldn't create %s",
					NULL,NULL,NULL, filename);
				return self;
			}
			else
			{
				[panel	orderOut:NULL];
				NXFreeAlertPanel(panel);
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
			NXFreeAlertPanel(panel);
			NXPing();
			NXRunAlertPanel ("Error","Could not stream to %s",
				NULL,NULL,NULL, filename);
			return self;
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
		NXFreeAlertPanel(panel);
		NXPing();
	}		
	
	if (newtexture)
		[texturePalette_i	initTextures ];

	return self;
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

- writeBuffer: (char const *)filename
{
	int		size;
	FILE	*stream;
	char	directory[1024];
	
	strcpy (directory, wadfile);
	StripFilename (directory);
	chdir (directory);
	
	size = (int)(buf_p - buffer);
	stream = fopen (filename,"w");
	if (!stream)
	{
		NXRunAlertPanel("ERROR!","Can't open %s! Someone must be"
			" messing with it!","OK",NULL,NULL,filename);
		free(buffer);
		return self;
	}

	fwrite (buffer, size, 1, stream);
	fclose (stream);
	printf ("%s:  %i bytes\n", filename, size);

	free (buffer);
			
	return self;
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
	[self writeBuffer: string];

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
	
			*list_p++ = LongSwap ((unsigned int)(buf_p-buffer));
			tex = (maptexture_t *)buf_p;
			buf_p += sizeof(*tex) - sizeof(tex->patches);
			
			strncpy(tex->name,wtex->name,8);   // JR 4/5/93
			tex->masked = false;
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
		[self writeBuffer: txtrname];
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

- saveDoomLumps
{
	chdir (mapwads);
	[self writePatchNames];
	[self writeDoomTextures];
	
	return self;
}

//====================================================
//
//	Initialize and display the thermometer
//
//====================================================
- (void)initThermo:(char *)title message:(char *)msg
{
#ifdef REDOOMED
	[thermoTitle_i	setStringValue:RDE_NSStringFromCString(title)];
	[thermoMsg_i	setStringValue:RDE_NSStringFromCString(msg)];
#else // Original
	[thermoTitle_i	setStringValue:title];
	[thermoMsg_i	setStringValue:msg];
#endif

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
	[thermoView_i setNeedsDisplay:YES];
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

#ifdef REDOOMED
@implementation DoomProject (RDEUtilities)

// rdePromptUserForWADfileLocation: ReDoomEd utility method to allow the user to locate a
// local copy of the project's wadfile when the project's current wadfile path is invalid

- (BOOL) rdePromptUserForWADfileLocation
{
    NSString *nameOfWADfile, *locateButtonTitle, *openPanelTitle, *pathToWADfile = nil;
    NSInteger alertReturnCode;
    NSOpenPanel *openPanel;

    nameOfWADfile = [RDE_NSStringFromCString(wadfile) lastPathComponent];

    if ([[nameOfWADfile pathExtension] isEqualToString: @"wad"])
    {
        openPanelTitle = [NSString stringWithFormat: @"Locate \"%@\"", nameOfWADfile];
    }
    else
    {
        openPanelTitle = @"Locate the project's WADfile";
    }

    locateButtonTitle = [openPanelTitle stringByAppendingString: @"..."];

    alertReturnCode = NSRunAlertPanel(@"Error",
                                        @"The project's WADfile was not found at \"%s\".",
                                        locateButtonTitle, @"Cancel", nil, wadfile);

    if (alertReturnCode != NSAlertDefaultReturn)
    {
        return NO;
    }

    openPanel = [NSOpenPanel openPanel];
    [openPanel setTitle: openPanelTitle];
    [openPanel setAllowedFileTypes: [NSArray arrayWithObject: @"wad"]];
    [openPanel setCanChooseDirectories: NO];
    [openPanel setAllowsMultipleSelection: NO];

    while (!pathToWADfile)
    {
        if ([openPanel runModal] == NSFileHandlingPanelCancelButton)
        {
            return NO;
        }

        pathToWADfile = [openPanel filename];

        if ([pathToWADfile length] > RDE_MAX_FILEPATH_LENGTH)
        {
            NSRunAlertPanel(@"Nope.", @"WADfile path is too long.", @"OK", nil, nil);
            pathToWADfile = nil;
        }
    }

    strcpy(wadfile, pathToWADfile.fileSystemRepresentation);

    return YES;
}

// rdePromptUserForPNGExport: ReDoomEd utility method to notify the user that map printing is
// unsupported in ReDoomEd, and to let them choose whether to export to PNG instead

- (BOOL) rdePromptUserForPNGExport
{
    NSInteger alertReturnCode;

    alertReturnCode =
        NSRunAlertPanel(@"Can't print maps. Export to PNG instead?",
                        @"ReDoomEd currently doesn't support DoomEd's map-printing feature, "
                        "however, maps can now be exported as PNG-format image files.\n\n"
                        "Images will be exported at the same zoom level as the current map.",
                        @"Export as PNG...", @"Cancel",  nil);

    return (alertReturnCode == NSAlertDefaultReturn) ? YES : NO;
}

@end
#endif // REDOOMED

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
	char	string[1024];


	va_start(argptr, error);

#ifdef REDOOMED
	// prevent buffer overflows: *sprintf() -> *snprintf() in cases where input strings
	// might be too long for the destination buffer
	vsnprintf (string,sizeof(string),error,argptr);
#else // Original
	vsprintf (string,error,argptr);
#endif

	va_end (argptr);
	NXRunAlertPanel("Error","%s",NULL,NULL,NULL, string);
	[NXApp terminate: NULL];
}

//=======================================================
//
//	Draw a red outline (must already be lockFocus'ed on something)
//
//=======================================================
void DE_DrawOutline(NXRect *r)
{
	PSsetrgbcolor ( 148,0,0 );
	PSmoveto ( r->origin.x, r->origin. y );
	PSsetlinewidth( 2.0 );
	PSlineto (r->origin.x+r->size.width-1,r->origin.y);
	PSlineto (r->origin.x+r->size.width-1,
			r->origin.y+r->size.height-1);
	PSlineto (r->origin.x,r->origin.y+r->size.height-1);
	PSlineto (r->origin.x,r->origin.y);
	PSstroke ();

	return;	
}

#ifdef REDOOMED
//  RDE_FileMatchStringAndGetString() is a utility function for reading a string value from
// a file (immediately following a matching prefix string); Replaced fscanf() calls with
// RDE_FileMatchStringAndGetString() in loadPV1File: in order to prevent buffer overflows,
// support filepaths with spaces, & allow reading empty filepaths

#   define macroFileSkipWhitespaceChars(stream)                                         \
            {                                                                           \
                char fileChar;                                                          \
                do {fileChar = fgetc(stream);} while (isspace(fileChar));               \
                ungetc(fileChar, stream);                                               \
            }

static bool RDE_FileMatchStringAndGetString(FILE *stream, const char *matchStr,
                                            char *returnedStr, int maxReturnedStrLength)
{
	char fileLineStr[1024], *remainderStr;
	size_t matchStrLength, remainderStrLength;

	if (!stream
	    || !matchStr
	    || !returnedStr)
	{
		goto ERROR;
	}

	matchStrLength = strlen(matchStr);

	if ((matchStrLength < 1) || (matchStrLength >= sizeof(fileLineStr)))
	{
		goto ERROR;
	}

	macroFileSkipWhitespaceChars(stream);

	if (!fgets(fileLineStr, sizeof(fileLineStr), stream))
	{
		goto ERROR;
	}

	if (strncmp(fileLineStr, matchStr, matchStrLength) != 0)
	{
		goto ERROR;
	}

	remainderStr = &fileLineStr[matchStrLength];

	remainderStrLength = strlen(remainderStr);

	// remove trailing newline from fgets() string
	if (remainderStr[remainderStrLength-1] == '\n')
	{
		remainderStr[remainderStrLength-1] = 0;
		remainderStrLength--;
	}

	if (remainderStrLength > maxReturnedStrLength)
	{
		goto ERROR;
	}

	macroFileSkipWhitespaceChars(stream);

	strcpy(returnedStr, remainderStr);

	return YES;

ERROR:
	return NO;
}

#endif
