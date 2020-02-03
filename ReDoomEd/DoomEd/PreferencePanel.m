// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "PreferencePanel.h"
#import "MapWindow.h"
#import "DoomProject.h"

PreferencePanel *prefpanel_i;

char		*ucolornames[NUMCOLORS] =
{
	"back_c",
	"grid_c",
	"tile_c",
	"selected_c",
	"point_c",
	"onesided_c",
	"twosided_c",
	"area_c",
	"thing_c",
	"special_c"
};

char		launchTypeName[] = "launchType";
char		projectPathName[] = "projectPath";
char		*openupNames[NUMOPENUP] =
{
	"texturePaletteOpen",
	"lineInspectorOpen",
	"lineSpecialsOpen",
	"errorLogOpen",
	"sectorEditorOpen",
	"thingPanelOpen",
	"sectorSpecialsOpen",
	"textureEditorOpen"
};
int			openupValues[NUMOPENUP];
	
#ifdef REDOOMED
@interface NSString (RDEUtilities_PreferencePanel)	
- (NSString *) rdeProjectPathStringWithTrailingPathSeparator;
@end
#endif

@implementation PreferencePanel

#ifdef REDOOMED
// Cocoa version
+ (void) initialize
#else // Original
+ initialize
#endif
{
	static NXDefaultsVector defaults = 
	{
		{"back_c","1:1:1"},
#ifdef REDOOMED
		// tweaked default color values for better contrast
		{"grid_c","0.97:0.97:0.97"},
		{"tile_c","0.93:0.93:0.93"},
#else // Original
		{"grid_c","0.8:0.8:0.8"},
		{"tile_c","0.5:0.5:0.5"},
#endif
		{"selected_c","1:0:0"},

		{"point_c","0:0:0"},
		{"onesided_c","0:0:0"},
#ifdef REDOOMED
		// tweaked default color values for better contrast
		{"twosided_c","0:0.69:0"},
#else // Original
		{"twosided_c","0.5:1:0.5"},
#endif
		{"area_c","1:0:0"},
		{"thing_c","1:1:0"},
#ifdef REDOOMED
		// tweaked default color values for better contrast
		{"special_c","0:0.69:0"},
#else // Original
		{"special_c","0.5:1:0.5"},
#endif
		
//		{"launchType","1"},
		{launchTypeName,"1"},

#ifdef REDOOMED
		// don't use hard-coded project paths
		{projectPathName,""},
		// leave panels hidden on launch
		{"texturePaletteOpen",	"0"},
		{"lineInspectorOpen",	"0"},
		{"lineSpecialsOpen",	"0"},
#else // Original
#   if 1
//		{"projectPath","/aardwolf/DoomMaps/project.dpr"},
		{projectPathName,"/aardwolf/DoomMaps/project.dpr"},
#   else
		{"projectPath","/RavenDev/maps/project.dpr"},
#   endif
		{"texturePaletteOpen",	"1"},
		{"lineInspectorOpen",	"1"},
		{"lineSpecialsOpen",	"1"},
#endif // REDOOMED

		{"errorLogOpen",		"0"},

#ifdef REDOOMED
		// leave panels hidden on launch
		{"sectorEditorOpen",	"0"},
#else // Original
		{"sectorEditorOpen",	"1"},
#endif

		{"thingPanelOpen",		"0"},
		{"sectorSpecialsOpen",	"0"},
		{"textureEditorOpen",	"0"},
		{NULL}
	};

	NXRegisterDefaults(APPDEFAULTS, defaults);

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

- getColor: (NXColor *)clr fromString: (char const *)string
{
	float	r,g,b;
	
	sscanf (string,"%f:%f:%f",&r,&g,&b);
	*clr = NXConvertRGBToColor(r,g,b);
	return self;
}

- getString: (char *)string fromColor: (NXColor *)clr
{
	char		temp[40];
	float	r,g,b;
	
	r = NXRedComponent(*clr);
	g = NXGreenComponent(*clr);
	b = NXBlueComponent(*clr);
	
	sprintf (temp,"%1.2f:%1.2f:%1.2f",r,g,b);
	strcpy (string, temp);
	
	return self;
}

- getLaunchThingTypeFrom:(const char *)string
{
	sscanf(string,"%d",&launchThingType);
	return self;
}

- getProjectPathFrom:(const char *)string
{
#ifdef REDOOMED
	// prevent buffer overflows: check string length
	if (!string || (strlen(string) > RDE_MAX_FILEPATH_LENGTH))
	{
		return self;
	}
#endif

	sscanf(string,"%s",projectPath);
	return self;
}


/*
=====================
=
= init
=
=====================
*/

- init
{
	int		i;
	int		val;
	
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	prefpanel_i = self;
	window_i = NULL;		// until nib is loaded
	
	for (i=0 ; i<NUMCOLORS ; i++)
		[self getColor: &color[i]
			fromString: NXGetDefaultValue(APPDEFAULTS, ucolornames[i])];
		
	[self		getLaunchThingTypeFrom:
				NXGetDefaultValue(APPDEFAULTS,launchTypeName)];

	[self		getProjectPathFrom:
				NXGetDefaultValue(APPDEFAULTS,projectPathName)];
	//
	// openup defaults
	//
	for (i = 0;i < NUMOPENUP;i++)
	{
		sscanf(NXGetDefaultValue(APPDEFAULTS,openupNames[i]),"%d",&val);
//		[[openupDefaults_i findCellWithTag:i] setIntValue:val];
		openupValues[i] = val;
	}


	return self;
}


/*
=====================
=
= appWillTerminate:
=
=====================
*/

- appWillTerminate:sender
{
	int		i;
	char	string[40];
	
	for (i=0 ; i<NUMCOLORS ; i++)
	{
		[self getString: string  fromColor:&color[i]];
		NXWriteDefault(APPDEFAULTS, ucolornames[i], string);
	}
	
	sprintf(string,"%d",launchThingType);
	NXWriteDefault(APPDEFAULTS,launchTypeName,string);
	
	NXWriteDefault(APPDEFAULTS,projectPathName,projectPath);
	
	for (i = 0;i < NUMOPENUP;i++)
	{
//		sprintf(string,"%d",(int)
//			[[openupDefaults_i findCellWithTag:i] intValue]);
		sprintf(string,"%d",openupValues[i]);
		NXWriteDefault(APPDEFAULTS,openupNames[i],string);
	}
	
	if (window_i)
		[window_i	saveFrameUsingName:PREFNAME];
	return self;	
}


/*
==============
=
= menuTarget:
=
==============
*/

- (IBAction)menuTarget:sender
{
	int		i;
	
	if (!window_i)
	{
		[NXApp 
			loadNibSection:	"preferences.nib"
			owner:			self
			withNames:		NO
		];

#ifdef REDOOMED
		// NSTextFields don't send their action message if their window resigns key while
		// they're being edited, and the text changes will be lost if the textfield's
		// content is changed programmatically before the window becomes key again;
		// to avoid losing the user's input, make edited textfields send their action
		// immediately if the panel resigns key
		[window_i rdeSetupTextfieldsToSendActionWhenPanelResignsKey];
#endif
			
		[window_i	setFrameUsingName:PREFNAME];
		
		colorwell[0] = backcolor_i;
		colorwell[1] = gridcolor_i;
		colorwell[2] = tilecolor_i;
		colorwell[3] = selectedcolor_i;
		colorwell[4] = pointcolor_i;
		colorwell[5] = onesidedcolor_i;
		colorwell[6] = twosidedcolor_i;
		colorwell[7] = areacolor_i;
		colorwell[8] = thingcolor_i;
		colorwell[9] = specialcolor_i;

		for (i=0 ; i<NUMCOLORS ; i++)
#ifdef REDOOMED
			[colorwell[i] setColor: RDE_NSColorFromNXColor(color[i])];
#else // Original
			[colorwell[i] setColor: color[i]];
#endif
			
		for (i = 0;i < NUMOPENUP;i++)
			[[openupDefaults_i	cellWithTag:i]
				setIntValue:openupValues[i]];
	}

	[launchThingType_i  	setIntValue:launchThingType];

#ifdef REDOOMED
	[projectDefaultPath_i	setStringValue:RDE_NSStringFromCString(projectPath)];
#else // Original
	[projectDefaultPath_i	setStringValue:projectPath];
#endif

	[window_i orderFront:self];
}

/*
==============
=
= colorChanged:
=
==============
*/

- (IBAction)colorChanged:sender
{
	NSArray *list;
	
// get current colors

	for (NSInteger i=0 ; i<NUMCOLORS ; i++)
#ifdef REDOOMED
		color[i] = RDE_NXColorFromNSColor([colorwell[i] color]);
#else // Original
		color[i] = [colorwell[i] color];
#endif

// update all windows
	list = [NSApp windows];
	for (NSWindow *win in list.reverseObjectEnumerator) {
		if ([win class] == [MapWindow class])
			[[(MapWindow*)win mapView] display];
	}
}

- (NXColor)colorFor: (int)ucolor
{
	return color[ucolor];
}

- (IBAction)launchThingTypeChanged:sender
{
	launchThingType = [sender	intValue];
}

- (int)getLaunchThingType
{
	return self.launchThingType;
}

@synthesize launchThingType;

- (IBAction)projectPathChanged:sender
{
#ifdef REDOOMED
	NSString *newProjectPathString = [sender stringValue];

	// expand to a full path, because loadProject: uses fopen(), which doesn't support tildes;
	// note: if the path's last character is a path separator ("/"), it may be removed
	newProjectPathString = [newProjectPathString stringByExpandingTildeInPath];

	// make sure the path's last character is a path separator, because StripFilename()
	// (called by -[DoomProject loadProject:]) chops the string at the last path separator
	newProjectPathString = [newProjectPathString rdeProjectPathStringWithTrailingPathSeparator];

	// prevent buffer overflows: check string length
	if (newProjectPathString
	    && ([newProjectPathString length] <= RDE_MAX_FILEPATH_LENGTH))
	{
		strcpy(projectPath, RDE_CStringFromNSString(newProjectPathString));
	}
	else
	{
		newProjectPathString = RDE_NSStringFromCString(projectPath);
	}

	// may have adjusted the path, so update the sender (preference panel's textfield)
	[sender setStringValue: newProjectPathString];
#else // Original
	strcpy(projectPath, [sender	stringValue] );
#endif
}

- (IBAction)openupChanged:sender
{
	id	cell = [sender selectedCell];
	openupValues[[cell tag]] = [cell intValue];
}

- (const char *)getProjectPath
{
	return	projectPath;
}

- (BOOL)openUponLaunch:(openup_e)type
{
	if (!openupValues[type])
		return FALSE;
	return TRUE;
}

@end

#ifdef REDOOMED
@implementation NSString (RDEUtilities_PreferencePanel)	

// rdeProjectPathStringWithTrailingPathSeparator: ReDoomEd utility method to return a project
// path that has a path separator ("/") at the end

- (NSString *) rdeProjectPathStringWithTrailingPathSeparator
{
	BOOL isDirectory;

	if ([self length]
	    && [[NSFileManager defaultManager] fileExistsAtPath: self isDirectory: &isDirectory]
	    && isDirectory
	    && ![self hasSuffix: @"/"])
	{
		return [self stringByAppendingString: @"/"];
	}

	return self;
}

@end
#endif
