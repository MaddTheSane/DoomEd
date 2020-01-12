/*
    RDEGNUstepGlue_MapViewRedrawing.m

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
//  Workaround for a GNUstep issue where panning or zooming the mapview doesn't always redraw
// the newly-exposed areas, leaving visual glitches;
//  Fixed by patching MapView's setBoundsOrigin: & setBoundsSize: methods to manually force a
// redraw (if the origin/size changed) with [self setNeedsDisplay: YES] 

#ifdef GNUSTEP

#import <Cocoa/Cocoa.h>
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"
#import "../DoomEd/MapView.h"


@implementation NSObject (RDEGNUstepGlue_MapViewRedrawing)

+ (void) rdeGSGlue_MapViewRedrawing_InstallPatches
{
    macroSwizzleInstanceMethod(MapView, setBoundsOrigin:, rdeGSPatch_SetBoundsOrigin:);

    macroSwizzleInstanceMethod(MapView, setBoundsSize:, rdeGSPatch_SetBoundsSize:);
}

+ (void) load
{
    macroPerformNSObjectSelectorAfterAppLoads(rdeGSGlue_MapViewRedrawing_InstallPatches);
}

@end

@implementation MapView (RDEGNUstepGlue_MapViewRedrawing)

- (void) rdeGSPatch_SetBoundsOrigin: (NSPoint) newOrigin
{
    NSPoint oldOrigin = [self bounds].origin;

    [self rdeGSPatch_SetBoundsOrigin: newOrigin];

    if (!NSEqualPoints(oldOrigin, newOrigin))
    {
        [self setNeedsDisplay: YES];
    }
}

- (void) rdeGSPatch_SetBoundsSize: (NSSize) newSize
{
    NSSize oldSize = [self bounds].size;

    [self rdeGSPatch_SetBoundsSize: newSize];

    if (!NSEqualSizes(oldSize, newSize))
    {
        [self setNeedsDisplay: YES];
    }
}

@end

#endif  // GNUSTEP

