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
	
	private(set) var projectPath: URL?
	
	private static var __once: () = {
		var defDict: [String: Any] = ["back_c": "1:1:1",
									  "grid_c": NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 0.97, green: 0.97, blue: 0.97, alpha: 1)),
									  "tile_c": NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 0.93, green: 0.93, blue: 0.93, alpha: 1)),
									  "selected_c": NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 1, green: 0, blue: 0, alpha: 1)),
									  "point_c": NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 1)),
									  "onesided_c": NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 1)),
									  "twosided_c": NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 0, green: 0.69, blue: 0, alpha: 1)),
									  "area_c": NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 1, green: 0, blue: 0, alpha: 1)),
									  "thing_c": NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 1, green: 1, blue: 0, alpha: 1)),
									  "special_c": NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 0.5, green: 1, blue: 0.5, alpha: 1)),
									  launchTypeName: 1,
									  projectPathName: "~/DoomMaps/",
									  "texturePaletteOpen": false,
									  "lineInspectorOpen": false,
									  "lineSpecialsOpen": false,
									  "errorLogOpen": false,
									  "sectorEditorOpen": false,
									  "thingPanelOpen": false,
									  "sectorSpecialsOpen": false,
									  "textureEditorOpen": false]
		
		UserDefaults.standard.register(defaults: defDict)
	}()
	
	public override init() {
		super.init()
		colorwell.reserveCapacity(10)

		_=PreferencePanel.__once
		
		let defaults = UserDefaults.standard
		for i in 0 ..< Int(ucolor_e.NUMCOLORS.rawValue) {
			color.append(colorFromDefault(forKey: ucolornames[i], defaults: defaults)!)
		}
		launchThingType = Int32(defaults.integer(forKey: launchTypeName))

		projectPath = defaults.url(forKey: projectPathName) ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("DoomMaps/", isDirectory: true)
		
		
		// openup defaults
		for i in 0 ..< Int(openup_e.NUMOPENUP.rawValue) {
			openupValues[i] = defaults.bool(forKey: openupNames[i])
		}
		
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

			for i in 0 ..< Int(ucolor_e.NUMCOLORS.rawValue) {
				colorwell[i].color = color[i]
			}
			for i in 0 ..< Int(openup_e.NUMOPENUP.rawValue) {
				openupDefaults.cell(withTag: i)?.state = openupValues[i] ? .on : .off
			}
		}
		
		launchThingType_i.intValue = launchThingType
		
		projectDefaultPath.stringValue = projectPath?.path ?? ""
		
		
		window.orderFront(self)
	}

	@IBAction open func colorChanged(_ sender: Any!) {
		for i in 0 ..< Int(ucolor_e.NUMCOLORS.rawValue) {
			color[i] = colorwell[i].color
		}
		
		// update all windows
		for window in NSApp.windows {
			if let mapWin = window as? MapWindow {
				mapWin.mapView.needsDisplay = true
			}
		}
	}

	@IBAction open func launchThingTypeChanged(_ sender: Any!) {
		let launchThingType1: Int = (sender as AnyObject).intValue
		launchThingType = Int32(launchThingType1)
	}

	@IBAction open func projectPathChanged(_ sender: Any!) {
		var newProjectPathString: String = (sender as AnyObject).stringValue ?? ""
		
		// expand to a full path, because loadProject: uses fopen(), which doesn't support tildes;
		// note: if the path's last character is a path separator ("/"), it may be removed
		newProjectPathString = (newProjectPathString as NSString).expandingTildeInPath

		// make sure the path's last character is a path separator, because StripFilename()
		// (called by -[DoomProject loadProject:]) chops the string at the last path separator
		newProjectPathString = rdeProjectPathWithTrailingPathSeparator(newProjectPathString)

		/*
		// TODO: prevent buffer overflows: check string length
		if (newProjectPathString
			&& ([newProjectPathString length] <= RDE_MAX_FILEPATH_LENGTH))
		{
			strcpy(projectPath, RDE_CStringFromNSString(newProjectPathString));
		}
		else
		{
			newProjectPathString = RDE_NSStringFromCString(projectPath);
		}

		*/
		projectPath = URL(fileURLWithPath: newProjectPathString)
		
		// may have adjusted the path, so update the sender (preference panel's textfield)
		(sender as AnyObject).setString(newProjectPathString)
	}

	@IBAction open func openupChanged(_ sender: Any!) {
		guard let cell: NSCell = (sender as AnyObject).selectedCell() else {
			return
		}
		
		openupValues[cell.tag] = cell.state == .on
	}
    
	@objc @discardableResult open func appWillTerminate(_ sender: Any!) -> Any! {
		let defaults = UserDefaults.standard
		for i in 0 ..< Int(ucolor_e.NUMCOLORS.rawValue) {
			let colorDat = NSKeyedArchiver.archivedData(withRootObject: color[i])
			defaults.set(colorDat, forKey: ucolornames[i])
		}
		
		defaults.set(Int(launchThingType), forKey: launchTypeName)
		defaults.set(projectPath, forKey: projectPathName)
		
		for i in 0 ..< Int(openup_e.NUMOPENUP.rawValue) {
			defaults.set(openupValues[i], forKey: openupNames[i])
		}
		
		window?.saveFrame(usingName: PREFNAME)
		return self
	}
    
	@objc func color(forColor ucolor: ucolor_e) -> NSColor {
		return color[Int(ucolor.rawValue)]
	}
	
	@objc(colorFor:) func color(for ucolor: ucolor_e) -> NXColor {
		RDE_NXColorFromNSColor(color[Int(ucolor.rawValue)])
	}

	open func getProjectPath() -> UnsafePointer<Int8>! {
		return (projectPath as NSURL?)?.fileSystemRepresentation ?? ("" as NSString).utf8String
	}

	@objc open func openUponLaunch(_ type: openup_e) -> Bool {
		if !openupValues[Int(type.rawValue)] {
			return false
		}
		return true
	}

    private(set) var launchThingType: Int32 = 0
}

/// `rdeProjectPathStringWithTrailingPathSeparator`: ReDoomEd utility method to return a project
/// path that has a path separator ("/") at the end
private func rdeProjectPathWithTrailingPathSeparator(_ path: String) -> String {
	var isDirectory: ObjCBool = false
	if path.count != 0,
		FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
		isDirectory.boolValue,
		!path.hasSuffix("/") {
		return path + "/"
	}
	return path
}

private func colorFromDefault(forKey key: String, defaults: UserDefaults = UserDefaults.standard) -> NSColor? {
	let rawObj = defaults.object(forKey: key)
	if let dataObj = rawObj as? Data {
		let aColor = NSKeyedUnarchiver.unarchiveObject(with: dataObj)
		return aColor as? NSColor
	} else if let rawStr = rawObj as? String {
		let scan = Scanner(string: rawStr)
		var r: Float = 0
		var g: Float = 0
		var b: Float = 0
		scan.scanFloat(&r)
		scan.scanString(":", into: nil)
		scan.scanFloat(&g)
		scan.scanString(":", into: nil)
		scan.scanFloat(&b)
		return NSColor(deviceRed: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
	}
	return nil
}
