//
//  PreferencePanelSwift.swift
//  ReDoomEd
//
//  Created by C.W. Betts on 2/7/20.
//

import Cocoa

private let ucolornames: [String] = [
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
]

private let launchTypeName = "launchType"
private let projectPathName = "projectPath"
private let openupNames = [
	"texturePaletteOpen",
	"lineInspectorOpen",
	"lineSpecialsOpen",
	"errorLogOpen",
	"sectorEditorOpen",
	"thingPanelOpen",
	"sectorSpecialsOpen",
	"textureEditorOpen"
]

private var openupValues = [Bool](repeating: false, count: Int(openup_e.NUMOPENUP.rawValue))

@objcMembers open class PreferencePanel: NSObject {
    @IBOutlet weak var backcolor: NSColorWell!
    @IBOutlet weak var gridcolor: NSColorWell!
    @IBOutlet weak var tilecolor: NSColorWell!
    @IBOutlet weak var selectedcolor: NSColorWell!
    @IBOutlet weak var pointcolor: NSColorWell!
    @IBOutlet weak var onesidedcolor: NSColorWell!
    @IBOutlet weak var twosidedcolor: NSColorWell!
    @IBOutlet weak var areacolor: NSColorWell!
    @IBOutlet weak var thingcolor: NSColorWell!
	@IBOutlet weak var specialcolor: NSColorWell!
	
	@IBOutlet weak var launchThingType_i: NSTextField!
	@IBOutlet weak var projectDefaultPath: NSTextField!
	@IBOutlet weak var openupDefaults: NSMatrix!
	
    @IBOutlet weak var window: NSPanel!

	private var colorwell = [NSColorWell]()
	private var color = [NSColor]()
	/*
		NSColorWell *colorwell[NUMCOLORS];
		NSColor	*color[NUMCOLORS];
		int		launchThingType;
	#ifdef REDOOMED
		char	projectPath[RDE_MAX_FILEPATH_LENGTH+1];

	*/
	
	private(set) var projectPath: URL?
	
	private static var __once: () = {
		/*
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

		*/
	}()
	
	public override init() {
		super.init()
		colorwell.reserveCapacity(10)

		_=PreferencePanel.__once
		
		prefpanel_i = self;
	}
    
    
	@IBAction open func menuTarget(_ sender: Any!) {
		
		if window == nil {
			NSApp.loadNibSection("preferences.nib", owner: self, withNames: false)
			
			// NSTextFields don't send their action message if their window resigns key while
			// they're being edited, and the text changes will be lost if the textfield's
			// content is changed programmatically before the window becomes key again;
			// to avoid losing the user's input, make edited textfields send their action
			// immediately if the panel resigns key
			window.rdeSetupTextfieldsToSendActionWhenPanelResignsKey()
			
			colorwell.append(backcolor)
			colorwell.append(gridcolor)
			colorwell.append(tilecolor)
			colorwell.append(selectedcolor)
			colorwell.append(pointcolor)
			colorwell.append(onesidedcolor)
			colorwell.append(twosidedcolor)
			colorwell.append(areacolor)
			colorwell.append(thingcolor)
			colorwell.append(specialcolor)

			/*
					for (i=0 ; i<NUMCOLORS ; i++)
			#ifdef REDOOMED
						[colorwell[i] setColor: color[i]];
			#else // Original
						[colorwell[i] setColor: color[i]];
			#endif
						
					for (i = 0;i < NUMOPENUP;i++)
						[[openupDefaults_i	cellWithTag:i]
						 setState:openupValues[i] ? NSControlStateValueOn : NSControlStateValueOff];

			*/
		}
		
		launchThingType_i.intValue = launchThingType
		
		projectDefaultPath.stringValue = projectPath?.path ?? ""
		
		
		window.orderFront(self)
	}

	@IBAction open func colorChanged(_ sender: Any!) {
		/*
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

		*/
	}

	@IBAction open func launchThingTypeChanged(_ sender: Any!) {
		let launchThingType1: Int = (sender as AnyObject).intValue
		launchThingType = Int32(launchThingType1)
	}

	@IBAction open func projectPathChanged(_ sender: Any!) {
		
	}

	@IBAction open func openupChanged(_ sender: Any!) {
		guard let cell: NSCell = (sender as AnyObject).selectedCell() else {
			return
		}
		
		openupValues[cell.tag] = cell.state == .on
	}

    
	@objc @discardableResult open func appWillTerminate(_ sender: Any!) -> Any! {
		return self
	}

    
	@objc func color(forColor ucolor: ucolor_e) -> NSColor! {
		return color[Int(ucolor.rawValue)]
	}
	
	func color(for ucolor: ucolor_e) -> NXColor {
		RDE_NXColorFromNSColor(color[Int(ucolor.rawValue)])
	}

	open func getProjectPath() -> UnsafePointer<Int8>! {
		return nil
	}

	@objc open func openUponLaunch(_ type: openup_e) -> Bool {
		if !openupValues[Int(type.rawValue)] {
			return false
		}
		return true
	}

    private(set) var launchThingType: Int32 = 0
	
	/*
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

	*/
}
