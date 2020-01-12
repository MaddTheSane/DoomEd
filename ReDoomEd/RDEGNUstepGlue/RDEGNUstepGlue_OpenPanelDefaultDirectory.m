/*
    RDEGNUstepGlue_OpenPanelDefaultDirectory.m

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
//  Set up GNUstep's NSOpenPanel to default to the home directory (instead of the root directory)

#ifdef GNUSTEP

#import <Cocoa/Cocoa.h>
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"


@implementation NSObject (RDEGNUstepGlue_OpenPanelDefaultDirectory)

+ (void) rdeGSGlue_OpenPanelDefaultDirectory_InstallPatches
{
    macroSwizzleInstanceMethod(NSOpenPanel, init, rdeGSPatch_Init);
}

+ (void) load
{
    macroPerformNSObjectSelectorAfterAppLoads(
                                        rdeGSGlue_OpenPanelDefaultDirectory_InstallPatches);
}

@end

@implementation NSOpenPanel (RDEGNUstepGlue_OpenPanelDefaultDirectory)

- (id) rdeGSPatch_Init
{
    self = [self rdeGSPatch_Init];

    if (self && ([[self directory] length] <= 1))
    {
        NSString *homeDirectory = NSHomeDirectory();

        if ([homeDirectory length])
        {
            [self setDirectory: homeDirectory];
        }
    }

    return self;
}

@end

#endif  // GNUSTEP

