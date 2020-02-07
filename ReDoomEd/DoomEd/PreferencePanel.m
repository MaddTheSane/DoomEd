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

static NSColor *getColorFromDefault(NSString *defKey, NSUserDefaults *defaults)
{
	id rawObj = [defaults objectForKey:defKey];
	if ([rawObj isKindOfClass:[NSData class]]) {
		NSColor *aColor = [NSKeyedUnarchiver unarchiveObjectWithData: rawObj];
		return aColor;
	} else if ([rawObj isKindOfClass:[NSString class]]) {
		//Old-style data
		NSScanner *scanner = [NSScanner scannerWithString:rawObj];
		float	r=0,g=0,b=0;
		
		[scanner scanFloat:&r];
		[scanner scanString:@":" intoString:nil];
		[scanner scanFloat:&g];
		[scanner scanString:@":" intoString:nil];
		[scanner scanFloat:&b];

		return [NSColor colorWithDeviceRed:r green:g blue:b alpha:1];
	}
	return nil;
}

@implementation PreferencePanel

// Cocoa version
+ (void) initialize
{
	NSDictionary *defDict = @{@"back_c": 		@"1:1:1",
							  @"grid_c": 		[NSKeyedArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed: 0.97 green: 0.97 blue: 0.97 alpha: 1]],
							  @"tile_c": 		[NSKeyedArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed: 0.93 green: 0.93 blue: 0.93 alpha: 1]],
							  @"selected_c": 	[NSKeyedArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed: 1 green: 0 blue: 0 alpha: 1]],
							  @"point_c":		[NSKeyedArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed: 0 green: 0 blue: 0 alpha: 1]],
							  @"onesided_c":	[NSKeyedArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed: 0 green: 0 blue: 0 alpha: 1]],
							  @"twosided_c":	[NSKeyedArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed: 0 green: 0.69 blue: 0 alpha: 1]],
							  @"area_c":		[NSKeyedArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed: 1 green: 0 blue: 0 alpha: 1]],
							  @"thing_c":		[NSKeyedArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed: 1 green: 1 blue: 0 alpha: 1]],
							  @"special_c":		[NSKeyedArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed: 0.5 green: 1 blue: 0.5 alpha: 1]],
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

	strncpy(projectPath, string, sizeof(projectPath));
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
	window = NULL;		// until nib is loaded
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
//		[[openupDefaults findCellWithTag:i] setIntValue:val];
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
//			[[openupDefaults findCellWithTag:i] intValue]);
		[defaults setBool:openupValues[i] forKey:openupNames[i]];
	}
	
	if (window)
		[window	saveFrameUsingName:PREFNAME];
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
	
	if (!window)
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
		[window rdeSetupTextfieldsToSendActionWhenPanelResignsKey];
#endif
			
		[window	setFrameUsingName:PREFNAME];
		
		colorwell[0] = backcolor;
		colorwell[1] = gridcolor;
		colorwell[2] = tilecolor;
		colorwell[3] = selectedcolor;
		colorwell[4] = pointcolor;
		colorwell[5] = onesidedcolor;
		colorwell[6] = twosidedcolor;
		colorwell[7] = areacolor;
		colorwell[8] = thingcolor;
		colorwell[9] = specialcolor;

		for (i=0 ; i<NUMCOLORS ; i++)
#ifdef REDOOMED
			[colorwell[i] setColor: color[i]];
#else // Original
			[colorwell[i] setColor: color[i]];
#endif
			
		for (i = 0;i < NUMOPENUP;i++)
			[[openupDefaults	cellWithTag:i]
			 setState:openupValues[i] ? NSControlStateValueOn : NSControlStateValueOff];
	}

	[launchThingType_i  	setIntValue:launchThingType];

#ifdef REDOOMED
	[projectDefaultPath	setStringValue:RDE_NSStringFromCString(projectPath)];
#else // Original
	[projectDefaultPath_i	setStringValue:projectPath];
#endif

	[window orderFront:self];
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
