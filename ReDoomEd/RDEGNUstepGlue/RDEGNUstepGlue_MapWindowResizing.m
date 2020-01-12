/*
    RDEGNUstepGlue_MapWindowResizing.m

    Copyright 2019 Josh Freeman
    http://www.twilightedge.com

    This file is part of ReDoomEd for GNUstep. ReDoomEd is a Doom game map editor,
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
//  Workaround for a GNUstep issue where manually resizing the map window (user dragging a
// window edge) can cause the mapview to scroll by a large amount - this is because GNUstep
// currently doesn't send windowWillResize:toSize: messages to NSWindow delegates, and
// MapWindow uses that delegate method to store the mapview's initial scroll position relative
// to the screen, so it can be restored later in windowDidResize: (preserving the map's screen
// position, regardless of the repositioned window borders) - if the initial scroll position
// isn't set up, windowDidResize: will scroll the mapview to an incorrect location;
//  The (partial) fix is to patch MapWindow's windowDidResize: method to manually call
// windowWillResize:toSize: so the initial scroll position is set, though it will be based on
// the new (post-resize) size rather than the original (pre-resize) size - this fixes the
// incorrect scroll location, but it doesn't prevent the mapview from shifting its screen
// position as the window resizes (NSScrollView's default resizing behavior is to preserve its
// content view's scrollpoint relative to its own bounds, not relative to the screen)

#ifdef GNUSTEP

#import <Cocoa/Cocoa.h>
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"
#import "../DoomEd/MapWindow.h"


@implementation NSObject (RDEGNUstepGlue_MapWindowResizing)

+ (void) rdeGSGlue_MapWindowResizing_InstallPatches
{
    macroSwizzleInstanceMethod(MapWindow, windowDidResize:, rdeGSPatch_WindowDidResize:);
}

+ (void) load
{
    macroPerformNSObjectSelectorAfterAppLoads(rdeGSGlue_MapWindowResizing_InstallPatches);
}

@end

@implementation MapWindow (RDEGNUstepGlue_MapWindowResizing)

- (void) rdeGSPatch_WindowDidResize: (NSNotification *) notification
{
    [self windowWillResize: self toSize: [self frame].size];

    [self rdeGSPatch_WindowDidResize: notification];
}

@end

#endif  // GNUSTEP

