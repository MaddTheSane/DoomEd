/*
    RDEOSXGlue_OpenPanelTitles.m

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

//  On OS X 10.11 El Capitan & later, NSOpenPanels no longer display their title (?), so as a
// workaround, the title text is displayed using the panel's message textfield

#ifdef __APPLE__

#import <Cocoa/Cocoa.h>
#import "RDEOSXRuntimeVersionMacros.h"
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"


#define RDE_MAC_OS_X_RUNTIME_CHECK__OPEN_PANELS_DONT_DISPLAY_TITLES     \
                (_RDE_MAC_OS_X_RUNTIME_VERSION_IS_AT_LEAST_10_(11))


@implementation NSObject (RDEOSXGlue_OpenPanelTitles)

+ (void) rdeOSXGlue_OpenPanelTitles_InstallPatches
{
    macroSwizzleInstanceMethod(NSOpenPanel, setTitle:, rdeOSXPatch_SetTitle:);
}

+ (void) load
{
    if (RDE_MAC_OS_X_RUNTIME_CHECK__OPEN_PANELS_DONT_DISPLAY_TITLES)
    {
        macroPerformNSObjectSelectorAfterAppLoads(rdeOSXGlue_OpenPanelTitles_InstallPatches);
    }
}

@end

@implementation NSOpenPanel (RDEOSXGlue_OpenPanelTitles)

- (void) rdeOSXPatch_SetTitle: (NSString *) title
{
    [super setTitle: title];

    if (title)
    {
        // use the panel's message textfield to display the hidden title text
        [self setMessage: title];
    }
}

@end

#endif  // __APPLE__
