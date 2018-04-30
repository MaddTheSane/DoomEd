
#import "PreferencePanel.h"
#import "MapWindow.h"
#import "DoomProject.h"

PreferencePanel *prefpanel_i;

NSString	* const ucolornames[NUMCOLORS] =
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

NSString	* const launchTypeName = @"launchType";
NSString	* const projectPathName = @"projectPath";
NSString	* const openupNames[NUMOPENUP] =
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
BOOL		openupValues[NUMOPENUP];
	
@implementation PreferencePanel
@synthesize projectPath;

+ (void) initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSDictionary *defaults = @{
								   @"back_c":@"1:1:1",
								   @"grid_c":@"0.8:0.8:0.8",
								   @"tile_c":@"0.5:0.5:0.5",
								   @"selected_c":@"1:0:0",
								   
								   @"point_c":@"0:0:0",
								   @"onesided_c":@"0:0:0",
								   @"twosided_c":@"0.5:1:0.5",
								   @"area_c":@"1:0:0",
								   @"thing_c":@"1:1:0",
								   @"special_c":@"0.5:1:0.5",
								   
								   //		{"launchType":@"1"},
								   launchTypeName:@"1",
#if 1
								   //		{"projectPath":@"/aardwolf/DoomMaps/project.dpr"},
								   projectPathName:@"/aardwolf/DoomMaps/project.dpr",
#else
								   "projectPath":@"/RavenDev/maps/project.dpr",
#endif
								   @"texturePaletteOpen": @YES,
								   @"lineInspectorOpen": @YES,
								   @"lineSpecialsOpen": @YES,
								   @"errorLogOpen": @NO,
								   @"sectorEditorOpen": @YES,
								   @"thingPanelOpen": @NO,
								   @"sectorSpecialsOpen": @NO,
								   @"textureEditorOpen": @NO,
								   };
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	});
}

- (NSColor *) getColorFromCString: (char const *)string
{
	float r, g, b;
	
	sscanf(string, "%f:%f:%f", &r, &g, &b);
	return [NSColor colorWithRed:r green:g blue:b alpha:1.0];
}

- (NSColor *) getColorFromString: (NSString*)string
{
	//TODO: Use NSScanner
	return [self getColorFromCString:string.UTF8String];
}

- (NSString *) getStringFromColor: (NSColor *)clr
{
	CGFloat r,g,b;

	r = [clr redComponent];
	g = [clr greenComponent];
	b = [clr blueComponent];

	return [NSString stringWithFormat:@"%1.2f:%1.2f:%1.2f", r, g, b];
}


/*
=====================
=
= init
=
=====================
*/

- (instancetype)init
{
	if (self = [super init]) {
	int		i;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	prefpanel_i = self;
	window_i = NULL;		// until nib is loaded

	for (i=0 ; i<NUMCOLORS ; i++)
		color[i] = [self getColorFromString:
		    [defaults stringForKey:ucolornames[i]]];

		launchThingType = (int)[defaults integerForKey:launchTypeName];
		
		projectPath = [[defaults stringForKey:projectPathName] copy];
	//
	// openup defaults
	//
	for (i = 0;i < NUMOPENUP;i++)
	{
		openupValues[i] = [defaults boolForKey:openupNames[i]];
	}
	}

	return self;
}

- (void)dealloc
{
	[projectPath release];
	
	[super dealloc];
}


/*
=====================
=
= applicationWillTerminate:
=
=====================
*/

- (void)applicationWillTerminate: (NSNotification *)notification
{
	int i;
	NSString *string;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	for (i=0 ; i<NUMCOLORS ; i++)
	{
		string = [self getStringFromColor:color[i]];
		[defaults setObject:string forKey:ucolornames[i]];
	}

	[defaults setInteger:launchThingType forKey:launchTypeName];

	[defaults setObject:projectPath forKey:projectPathName];

	for (i = 0;i < NUMOPENUP;i++)
	{
//		sprintf(buf, "%d", (int)
//			[[openupDefaults_i findCellWithTag:i] intValue]);
		[defaults setBool:openupValues[i] forKey:openupNames[i]];
	}

	if (window_i)
		[window_i saveFrameUsingName:PREFNAME];
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
		[[NSBundle mainBundle] loadNibNamed: @"preferences.nib"
			owner: self
			topLevelObjects:nil];

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
			[colorwell[i] setColor: color[i]];
			
		for (i = 0;i < NUMOPENUP;i++)
			[[openupDefaults_i	cellWithTag:i]
				setIntValue:openupValues[i]];
	}

	[launchThingType_i  	setIntValue:launchThingType];
	[projectDefaultPath_i	setStringValue:projectPath];

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
	NSInteger i;
	NSWindow *win;
	NSArray *winList;

// get current colors

	for (i=0 ; i<NUMCOLORS ; i++)
		color[i] = [colorwell[i] color];

// update all windows
	winList = [[NSApplication sharedApplication] windows];
	i = [winList count];
	while (--i >= 0)
	{
		win = [winList objectAtIndex: i];
		if ([win isKindOfClass:[MapWindow class]])
			[[(MapWindow *)win mapView] setNeedsDisplay:YES];
	}
}

- (NSColor *)colorFor: (ucolor_e)ucolor
{
	return color[ucolor];
}

- (IBAction)launchThingTypeChanged:sender
{
	launchThingType = [sender intValue];
}

- (int)getLaunchThingType
{
	return	launchThingType;
}

- (IBAction)projectPathChanged:sender
{
	self.projectPath = [sender stringValue];
}

- (IBAction)openupChanged:sender
{
	id	cell = [sender selectedCell];
	openupValues[[cell tag]] = [cell intValue];
}

- (const char *)getProjectPath
{
	return	projectPath.fileSystemRepresentation;
}

- (BOOL)openUponLaunch:(openup_e)type
{
	if (!openupValues[type])
		return FALSE;
	return TRUE;
}

@end
