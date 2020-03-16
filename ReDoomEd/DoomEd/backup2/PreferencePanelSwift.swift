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
		var defDict: [String: Any] =
			[ucolornames[0]: "1:1:1",
			 ucolornames[1]: NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 0.97, green: 0.97, blue: 0.97, alpha: 1)),
			 ucolornames[2]: NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 0.93, green: 0.93, blue: 0.93, alpha: 1)),
			 ucolornames[3]: NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 1, green: 0, blue: 0, alpha: 1)),
			 ucolornames[4]: NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 1)),
			 ucolornames[5]: NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 1)),
			 ucolornames[6]: NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 0, green: 0.69, blue: 0, alpha: 1)),
			 ucolornames[7]: NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 1, green: 0, blue: 0, alpha: 1)),
			 ucolornames[8]: NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 1, green: 1, blue: 0, alpha: 1)),
			 ucolornames[9]: NSKeyedArchiver.archivedData(withRootObject: NSColor(deviceRed: 0.5, green: 1, blue: 0.5, alpha: 1)),
			 launchTypeName: 1,
			 projectPathName: "~/DoomMaps/",
			 openupNames[0]: false,
			 openupNames[1]: false,
			 openupNames[2]: false,
			 openupNames[3]: false,
			 openupNames[4]: false,
			 openupNames[5]: false,
			 openupNames[6]: false,
			 openupNames[7]: false]
		
		UserDefaults.standard.register(defaults: defDict)
	}()
	
	public override init() {
		super.init()
		colorwell.reserveCapacity(10)
		color.reserveCapacity(10)
		openupValues.reserveCapacity(10)

		_=PreferencePanel.__once
		
		let defaults = UserDefaults.standard
		for key in ucolornames {
			color.append(colorFromDefault(forKey: key, defaults: defaults)!)
		}
		launchThingType = Int32(defaults.integer(forKey: launchTypeName))

		projectPath = defaults.url(forKey: projectPathName) ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("DoomMaps/", isDirectory: true)
		
		
		// openup defaults
		for (i, name) in openupNames.enumerated() {
			openupValues[i] = defaults.bool(forKey: name)
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

			for (well, color) in zip(colorwell, color) {
				well.color = color
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
		//newProjectPathString = newProjectPathString

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
		(sender as? NSTextField)?.stringValue = newProjectPathString
	}

	@IBAction open func openupChanged(_ sender: Any!) {
		guard let cell: NSCell = (sender as AnyObject?)?.selectedCell() else {
			return
		}
		
		openupValues[cell.tag] = cell.state == .on
	}
    
	@objc open func appWillTerminate(_ sender: Any!) {
		let defaults = UserDefaults.standard
		for (col, name) in zip(color, ucolornames) {
			let colorDat: Data
			if #available(OSX 10.13, *) {
				colorDat = try! NSKeyedArchiver.archivedData(withRootObject: col, requiringSecureCoding: true)
			} else {
				colorDat = NSKeyedArchiver.archivedData(withRootObject: col)
			}
			defaults.set(colorDat, forKey: name)
		}
		
		defaults.set(Int(launchThingType), forKey: launchTypeName)
		defaults.set(projectPath, forKey: projectPathName)
		
		for (val, name) in zip(openupValues, openupNames) {
			defaults.set(val, forKey: name)
		}
		
		window?.saveFrame(usingName: PREFNAME)
	}
    
	@objc func color(forColor ucolor: ucolor_e) -> NSColor {
		return color[Int(ucolor.rawValue)]
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

private func colorFromDefault(forKey key: String, defaults: UserDefaults = UserDefaults.standard) -> NSColor? {
	let rawObj = defaults.object(forKey: key)
	if let dataObj = rawObj as? Data {
		if #available(OSX 10.13, *) {
			return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: dataObj)
		} else {
			let aColor = NSKeyedUnarchiver.unarchiveObject(with: dataObj)
			return aColor as? NSColor
		}
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
