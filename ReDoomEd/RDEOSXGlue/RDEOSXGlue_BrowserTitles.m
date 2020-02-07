/*
    RDEOSXGlue_BrowserTitles.m

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

//  On OS X 10.6 Snow Leopard & later, NSBrowser titles are invisible until the browser's
// resized.
//  Workaround is to temporarily change the width of the browser when it's loaded, so the title
// becomes visible.

#ifdef __APPLE__

#import <Cocoa/Cocoa.h>
#import "RDEOSXRuntimeVersionMacros.h"
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"


#define RDE_MAC_OS_X_RUNTIME_CHECK__HAS_BROWSER_TITLE_DISPLAY_ISSUE     \
                (_RDE_MAC_OS_X_RUNTIME_VERSION_IS_AT_LEAST_10_(6))


@interface NSBrowser (RDEOSXGlue_BrowserTitles)

- (void) rdeOSXPatch_AwakeFromNib;
- (void) rdeOSXGlue_UnhideTitle;

@end

@implementation NSObject (RDEOSXGlue_BrowserTitles)

+ (void) rdeOSXGlue_BrowserTitles_InstallPatches
{
    macroSwizzleInstanceMethod(NSBrowser, awakeFromNib, rdeOSXPatch_AwakeFromNib);
}

+ (void) load
{
    if (RDE_MAC_OS_X_RUNTIME_CHECK__HAS_BROWSER_TITLE_DISPLAY_ISSUE)
    {
        macroPerformNSObjectSelectorAfterAppLoads(rdeOSXGlue_BrowserTitles_InstallPatches);
    }
}

@end

@implementation NSBrowser (RDEOSXGlue_BrowserTitles)

- (void) rdeOSXPatch_AwakeFromNib
{
    [self rdeOSXPatch_AwakeFromNib];

    if ([self isTitled])
    {
        [self rdeOSXGlue_UnhideTitle];
    }
}

- (void) rdeOSXGlue_UnhideTitle
{
    NSSize originalSize, temporarySize;

    if (![self isTitled])
    {
        return;
    }

    // temporarily change the width of the browser - resizing causes the title to appear

    originalSize = [self frame].size;
    temporarySize = NSMakeSize(originalSize.width + 1, originalSize.height);

    [self setFrameSize: temporarySize];
    [self setFrameSize: originalSize];
}

@end

#endif  // __APPLE__
