/*
    RDEOSXGlue_MapWindowRedrawing.m

    Copyright 2019 Josh Freeman
    http://www.twilightedge.com

    This file is part of ReDoomEd for Mac OS X. ReDoomEd is a Doom game map editor,
    ported from id Software's DoomEd for NeXTSTEP.

    This file is distributed under the terms of the GNU Affero General Public License
    as published by the Free Software Foundation. You can redistribute it and/or modify
    it under the terms of version 3 of the License, or (at your option) any later
    version approved for distribution by this file's copyright holder (or an authorized
    proxy).

    ReDoomEd is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
    PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License along with
    this program. If not, see <http://www.gnu.org/licenses/>.
*/

//  On OS X 10.11 El Capitan & later, mapViews can display an out-of-date map after changing
// a thing's color or the difficulty display (Thing Inspector). Both of those actions call
// -[EditWorld redrawWindows], which sends all mapWindows a display message, expecting that to
// redraw the dirty mapView.
//  However, -[NSWindow display] no longer redraws the window's views (instead copying a cached
// version to the screen) unless a view's needsDisplay flag is set (previous OS X versions would
// redraw the views regardless).
//  The workaround is to patch -[EditWorld redrawWindows], and manually set the needsDisplay
// flag on all the mapWindows' mapViews before calling through to the original redrawWindows
// implementation.

#ifdef __APPLE__

#import <Cocoa/Cocoa.h>
#import "RDEOSXRuntimeVersionMacros.h"
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"
#import "../DoomEd/EditWorld.h"
#import "../DoomEd/MapWindow.h"


#define RDE_MAC_OS_X_RUNTIME_CHECK__NSWINDOW_DISPLAY_DOESNT_AUTOMATICALLY_REDRAW_VIEWS  \
                (_RDE_MAC_OS_X_RUNTIME_VERSION_IS_AT_LEAST_10_(11))


@interface MapWindow (RDEOSXGlue_MapWindowRedrawingUtilities)

- (void) rdeSetMapViewNeedsDisplay;

@end

@implementation NSObject (RDEOSXGlue_MapWindowRedrawing)

+ (void) rdeOSXGlue_MapWindowRedrawing_InstallPatches
{
    macroSwizzleInstanceMethod(EditWorld, redrawWindows, rdeOSXPatch_RedrawWindows);
}

+ (void) load
{
    if (RDE_MAC_OS_X_RUNTIME_CHECK__NSWINDOW_DISPLAY_DOESNT_AUTOMATICALLY_REDRAW_VIEWS)
    {
        macroPerformNSObjectSelectorAfterAppLoads(rdeOSXGlue_MapWindowRedrawing_InstallPatches);
    }
}

@end

@implementation EditWorld (RDEOSXGlue_MapWindowRedrawing)

- rdeOSXPatch_RedrawWindows
{
	[windowlist_i makeObjectsPerformSelector: @selector(rdeSetMapViewNeedsDisplay)];

    return [self rdeOSXPatch_RedrawWindows];
}

@end

@implementation MapWindow (RDEOSXGlue_MapWindowRedrawingUtilities)

- (void) rdeSetMapViewNeedsDisplay
{
    [mapview_i setNeedsDisplay: YES];
}

@end

#endif  // __APPLE__
