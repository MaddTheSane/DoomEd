/*
    RDEOSXGlue_ButtonImageAlignment.m

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

//  The three right-justified checkboxes on the Texture Edit panel have alignment issues on
// recent OS X versions - the checkbox images should line up as a vertical column, but somehow
// the buttons' imageHugsTitle flags (added in the 10.12 Sierra SDK) are set to YES (should
// default to NO), so the checkbox images instead align with the right edges of their button's
// title.
//  Workaround manually sets the checkboxes' imageHugsTitle flags to NO after the Texture Edit
// panel loads.


#ifdef __APPLE__

#import <Cocoa/Cocoa.h>
#import "RDEOSXRuntimeVersionMacros.h"
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"
#import "../DoomEd/TextureEdit.h"


#define RDE_MAC_OS_X_RUNTIME_CHECK__RIGHT_JUSTIFIED_BUTTON_IMAGES_NEED_ALIGNMENT_FIX    \
                (_RDE_MAC_OS_X_RUNTIME_VERSION_IS_AT_LEAST_10_(12))


@interface NSButton (RDEOSXGlue_NativeCocoa)

- (void) setImageHugsTitle: (BOOL) flag; // native Cocoa method from macOS 10.12 & later

@end

@interface NSButton (RDEOSXGlue_ButtonImageAlignmentUtilities)

- (void) rdeOSXGlue_ClearImageHugsTitleFlag;

@end

@interface TextureEdit (RDEOSXGlue_ButtonImageAlignment)

- (id) rdeOSXPatch_MenuTarget: (id) sender;

@end

@implementation NSObject (RDEOSXGlue_ButtonImageAlignment)

+ (void) rdeOSXGlue_ButtonImageAlignment_InstallPatches
{
    if (![NSButton instancesRespondToSelector: @selector(setImageHugsTitle:)])
    {
        return;
    }

    macroSwizzleInstanceMethod(TextureEdit, menuTarget:, rdeOSXPatch_MenuTarget:);
}

+ (void) load
{
    if (RDE_MAC_OS_X_RUNTIME_CHECK__RIGHT_JUSTIFIED_BUTTON_IMAGES_NEED_ALIGNMENT_FIX)
    {
        macroPerformNSObjectSelectorAfterAppLoads(
                                            rdeOSXGlue_ButtonImageAlignment_InstallPatches);
    }
}

@end

@implementation TextureEdit (RDEOSXGlue_ButtonImageAlignment)

- (id) rdeOSXPatch_MenuTarget: (id) sender
{
    id initial_window_i, returnValue;

    initial_window_i = window_i;
    returnValue = [self rdeOSXPatch_MenuTarget: sender];

    if (!initial_window_i && window_i)
    {
        // after the 'Texture Editor' panel loads (window_i becomes non-nil),
        // fix the image alignments of the panel's right-justified checkboxes

        [(NSButton *) outlinePatches_i rdeOSXGlue_ClearImageHugsTitleFlag];
        [(NSButton *) lockedPatch_i rdeOSXGlue_ClearImageHugsTitleFlag];
        [(NSButton *) centerPatch_i rdeOSXGlue_ClearImageHugsTitleFlag];
    }

    return returnValue;
}

@end

@implementation NSButton (RDEOSXGlue_ButtonImageAlignmentUtilities)

- (void) rdeOSXGlue_ClearImageHugsTitleFlag
{
    [self setImageHugsTitle: NO];
}

@end

#endif  // __APPLE__
