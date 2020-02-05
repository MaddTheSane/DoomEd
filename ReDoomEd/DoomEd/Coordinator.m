// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "Coordinator.h"
#import "MapWindow.h"
#import "MapView.h"
#import "PreferencePanel.h"
#import "EditWorld.h"
#import	"LinePanel.h"
#import	"SectorEditor.h"
#import	"TextureEdit.h"
#import	"TexturePalette.h"
#import	"ThingPanel.h"
#import	"DoomProject.h"

id	coordinator_i;

BOOL	debugflag = NO;

@implementation Coordinator

- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	coordinator_i = self;
	return self;
}

- (IBAction)toggleDebug: sender
{
	debugflag ^= 1;
}

- (IBAction)redraw: sender
{
	NSArray<NSWindow*> *list;
	MapWindow *win;
	
// update all windows
	list = [NXApp windows];
	for (win in list.reverseObjectEnumerator)
	{
		if ([win isKindOfClass:[MapWindow class]])
			[[win mapView] setNeedsDisplay:YES];
	}
}


/*
=============================================================================

					APPLICATION DELEGATE METHODS

=============================================================================
*/

- (BOOL)appAcceptsAnotherFile: sender
{
	if (![editworld_i loaded])
		return YES;
	return NO;
}
	
#ifdef REDOOMED
// Cocoa version
- (BOOL) application: (NSApplication *) app openFile: (NSString *) filename
#else // Original
- (int)app:			sender 
	openFile:		(const char *)filename 
	type:		(const char *)aType
#endif
{
	if ([doomproject_i loaded])
		return NO;

#ifdef REDOOMED
	[doomproject_i loadProjectWithFileURL: [NSURL fileURLWithPath:filename]];
#else // Original
	[doomproject_i loadProject: filename];
#endif

	return YES;
}


#ifdef REDOOMED
// Cocoa version
- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
#else // Original
- appDidInit: sender
#endif
{
#ifdef REDOOMED
	// -[PreferencePanel getProjectPath] no longer defaults to a hard-coded project path,
	// so it may return an empty string - added logic to check for this
	const char *defaultProjectPath = [prefpanel_i getProjectPath];

	if (![doomproject_i loaded]
		&& strlen(defaultProjectPath))
	{
		[doomproject_i loadProject: defaultProjectPath ];
	}

	// removed the call to [doomproject_i setDirtyProject:FALSE] because the project may
	// be dirty (if the user updated the wadfile location during the call to loadProject:)
#else // Original
	if (![doomproject_i loaded])
		[doomproject_i loadProject: [prefpanel_i  getProjectPath] ];
	[doomproject_i	setDirtyProject:FALSE];
#endif

	[toolPanel_i	setFrameUsingName:TOOLNAME];

#ifdef REDOOMED
	// the ToolPanel in DoomEd_Cocoa.nib doesn't automatically open on launch,
	// so that its frame can be moved (if necessary) before it becomes visible
	[toolPanel_i orderFront: self];

	// don't open panels if there's no project loaded
	if ([doomproject_i loaded]) {
#endif
	
	if ([prefpanel_i	openUponLaunch:texturePalette] == TRUE)
		[texturePalette_i	menuTarget:NULL];
	if ([prefpanel_i	openUponLaunch:lineInspector] == TRUE)
		[linepanel_i	menuTarget:NULL];
	if ([prefpanel_i	openUponLaunch:lineSpecials] == TRUE)
		[linepanel_i	activateSpecialList:NULL];
	if ([prefpanel_i	openUponLaunch:errorLog] == TRUE)
		[doomproject_i	displayLog:NULL];
	if ([prefpanel_i	openUponLaunch:sectorEditor] == TRUE)
		[sectorEdit_i	menuTarget:NULL];
	if ([prefpanel_i	openUponLaunch:thingPanel] == TRUE)
		[thingpanel_i	menuTarget:NULL];
	if ([prefpanel_i	openUponLaunch:sectorSpecials] == TRUE)
		[sectorEdit_i	activateSpecialList:NULL];
	if ([prefpanel_i	openUponLaunch:textureEditor] == TRUE)
		[textureEdit_i	menuTarget:NULL];

#ifdef REDOOMED
	// don't open panels if there's no project loaded
	}
#endif
	
	startupSound_i = [NSSound soundNamed:@"D_Dbite"];
	[startupSound_i	play];
	
#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

#ifdef REDOOMED
// Cocoa version
- (void) applicationWillTerminate: (NSNotification *) aNotification
#else // Original
- appWillTerminate: sender
#endif
{
	[doomproject_i	quit];
	[prefpanel_i appWillTerminate: self];
	[editworld_i appWillTerminate: self];
	
	[sectorEdit_i	saveFrame];
	[textureEdit_i	saveFrame];
	[linepanel_i	saveFrame];
	[texturePalette_i	saveFrame];
	[thingpanel_i	saveFrame];
	[doomproject_i	saveFrame];
	[toolPanel_i	saveFrameUsingName:TOOLNAME];
	
	printf("DoomEd terminated.\n\n");

#ifndef REDOOMED // Original (Disable for ReDoomEd - Cocoa version doesn't return a value)
	return self;
#endif
}

@end
