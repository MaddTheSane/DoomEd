// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "PreferencePanel.h"
#import "MapWindow.h"
#import "MapView.h"
#import "DoomProject.h"

PreferencePanel *prefpanel_i;

NSString		*const ucolornames[NUMCOLORS]  =
{
	@"back_c",
	@"grid_c",
	@"tile_c",
	@"selected_c",
	@"point_c",
	@"onesided_c",
	@"twosided_c",
	@"area_c",
	@"thing_c",
	@"special_c"
};

NSString	*const launchTypeName = @"launchType";
NSString	*const projectPathName = @"projectPath";
NSString	*const openupNames[NUMOPENUP] =
{
	@"texturePaletteOpen",
	@"lineInspectorOpen",
	@"lineSpecialsOpen",
	@"errorLogOpen",
	@"sectorEditorOpen",
	@"thingPanelOpen",
	@"sectorSpecialsOpen",
	@"textureEditorOpen"
};
BOOL			openupValues[NUMOPENUP];
	
#ifdef REDOOMED
@interface NSString (RDEUtilities_PreferencePanel)	
- (NSString *) rdeProjectPathStringWithTrailingPathSeparator;
@end
#endif

NSColor *getColorFromDefault(NSString *defKey, NSUserDefaults *defaults)
{
	id rawObj = [defaults objectForKey:defKey];
	if ([rawObj isKindOfClass:[NSData class]]) {
		NSColor *aColor = [NSKeyedUnarchiver unarchiveObjectWithData: rawObj];
		return aColor;
	} else if ([rawObj isKindOfClass:[NSString class]]) {
		//Old-style data
		const char *string = [(NSString*)rawObj UTF8String];
		float	r,g,b;
		
		sscanf (string,"%f:%f:%f",&r,&g,&b);
		return [NSColor colorWithDeviceRed:r green:g blue:b alpha:1];
	}
	return nil;
}

@implementation PreferencePanel

// Cocoa version
+ (void) initialize
{
	NSDictionary *defDict = @{@"back_c": 		@"1:1:1",
							  @"grid_c": 		@"0.97:0.97:0.97",
							  @"tile_c": 		@"0.93:0.93:0.93",
							  @"selected_c": 	@"1:0:0",
							  @"point_c":		@"0:0:0",
							  @"onesided_c":	@"0:0:0",
							  @"twosided_c":	@"0:0.69:0",
							  @"area_c":		@"1:0:0",
							  @"thing_c":		@"1:1:0",
							  @"special_c":		@"0.5:1:0.5",
							  launchTypeName:			@1,
							  projectPathName:			@"",
							  @"texturePaletteOpen":	@NO,
							  @"lineInspectorOpen":		@NO,
							  @"lineSpecialsOpen":		@NO,
							  @"errorLogOpen":			@NO,
							  @"sectorEditorOpen":		@NO,
							  @"thingPanelOpen":		@NO,
							  @"sectorSpecialsOpen":	@NO,
							  @"textureEditorOpen":		@NO};
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defDict];
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
	
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	prefpanel_i = self;
	window_i = NULL;		// until nib is loaded
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	for (i=0 ; i<NUMCOLORS ; i++) {
		color[i] = getColorFromDefault(ucolornames[i], defaults);
	}
		
	launchThingType = (int)[defaults integerForKey:launchTypeName];

	[self		getProjectPathFrom:
				NXGetDefaultValue(APPDEFAULTS,projectPathName.UTF8String)];
	//
	// openup defaults
	//
	for (i = 0;i < NUMOPENUP;i++)
	{
//		[[openupDefaults_i findCellWithTag:i] setIntValue:val];
		openupValues[i] = [defaults boolForKey:openupNames[i]];
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
	NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
	int		i;
	
	for (i=0 ; i<NUMCOLORS ; i++)
	{
		NSData *colorDat = [NSKeyedArchiver archivedDataWithRootObject:color[i]];
		[defaults setValue:colorDat forKey:ucolornames[i]];
	}
	
	[defaults setInteger:launchThingType forKey:launchTypeName];
	
	[defaults setValue:@(projectPath) forKey:projectPathName];
	
	for (i = 0;i < NUMOPENUP;i++)
	{
//		sprintf(string,"%d",(int)
//			[[openupDefaults_i findCellWithTag:i] intValue]);
		[defaults setBool:openupValues[i] forKey:openupNames[i]];
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
			[colorwell[i] setColor: color[i]];
#else // Original
			[colorwell[i] setColor: color[i]];
#endif
			
		for (i = 0;i < NUMOPENUP;i++)
			[[openupDefaults_i	cellWithTag:i]
			 setState:openupValues[i] ? NSControlStateValueOn : NSControlStateValueOff];
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
		color[i] = [colorwell[i] color];
#else // Original
		color[i] = [colorwell[i] color];
#endif

// update all windows
	list = [NSApp windows];
	for (NSWindow *win in list.reverseObjectEnumerator) {
		if ([win isKindOfClass:[MapWindow class]])
			[[(MapWindow*)win mapView] setNeedsDisplay:YES];
	}
}

- (NSColor*)colorForColor: (ucolor_e)ucolor;
{
	return color[ucolor];
}

- (NXColor)colorFor: (int)ucolor
{
	return RDE_NXColorFromNSColor(color[ucolor]);
}

- (IBAction)launchThingTypeChanged:sender
{
	launchThingType = [sender	intValue];
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
	NSButtonCell	*cell = [sender selectedCell];
	openupValues[[cell tag]] = [cell state] == NSControlStateValueOn;
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
