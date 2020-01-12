/*
    RDEGNUstepGlue_ThermoPanel.m

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
//  Workaround for a display issue on GNUstep that leaves the Thermo panel's background
// transparent - this is because the Thermo panel is only displayed while loading a project,
// and control isn't returned to the run loop (where automatic drawing is handled) until
// loading finishes (and after the panel's been hidden).
//  Fixed by patching -[DoomProject initThermo:message:] to manually send the panel a display
// message, forcing the background to draw before loading begins.

#ifdef GNUSTEP

#import <Cocoa/Cocoa.h>
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"
#import "../DoomEd/DoomProject.h"


@implementation NSObject (RDEGNUstepGlue_ThermoPanel)

+ (void) rdeGSGlue_ThermoPanel_InstallPatches
{
    macroSwizzleInstanceMethod(DoomProject, initThermo:message:, rdeGSPatch_InitThermo:message:);
}

+ (void) load
{
    macroPerformNSObjectSelectorAfterAppLoads(rdeGSGlue_ThermoPanel_InstallPatches);
}

@end

@implementation DoomProject (RDEGNUstepGlue_ThermoPanel)

- (id) rdeGSPatch_InitThermo: (char *) title message: (char *) msg
{
    id returnValue = [self rdeGSPatch_InitThermo: title message: msg];

    [thermoWindow_i display];

    return returnValue;
}

@end

#endif  // GNUSTEP

