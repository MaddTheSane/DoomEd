/*
    RDEGNUstepGlue_NSBrowser.m

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

// Preserve NSBrowser titles

#ifdef GNUSTEP

#import <Cocoa/Cocoa.h>
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"


@interface NSBrowser (RDEGNUstepGlue_NSBrowserUtilities)

- (NSString *) rdeGSGlue_TitleOfColumnZero;

- (void) rdeGSGlue_SetTitleOfColumnZero: (NSString *) title;

@end

@implementation NSObject (RDEGNUstepGlue_NSBrowser)

+ (void) rdeGSGlue_NSBrowser_InstallPatches
{
    macroSwizzleInstanceMethod(NSBrowser, loadColumnZero, rdeGSPatch_LoadColumnZero);

    macroSwizzleInstanceMethod(NSBrowser, reloadColumn:, rdeGSPatch_ReloadColumn:);
}

+ (void) load
{
    macroPerformNSObjectSelectorAfterAppLoads(rdeGSGlue_NSBrowser_InstallPatches);
}

@end

@implementation NSBrowser (RDEGNUstepGlue_NSBrowser)

- (void) rdeGSPatch_LoadColumnZero
{
    NSString *titleToRestore = [self rdeGSGlue_TitleOfColumnZero];

    [self rdeGSPatch_LoadColumnZero];

    if (titleToRestore)
    {
        [self rdeGSGlue_SetTitleOfColumnZero: titleToRestore];
    }
}

- (void) rdeGSPatch_ReloadColumn: (NSInteger) column
{
    NSString *titleToRestore = nil;

    if ((column == 0) && ([self lastColumn] >= 0))
    {
        titleToRestore = [self rdeGSGlue_TitleOfColumnZero];
    }

    [self rdeGSPatch_ReloadColumn: column];

    if (titleToRestore)
    {
        [self rdeGSGlue_SetTitleOfColumnZero: titleToRestore];
    }
}

- (NSString *) rdeGSGlue_TitleOfColumnZero
{
    NSString *title = nil;

    if ([self isTitled])
    {
        title = [[[self titleOfColumn: 0] retain] autorelease];

        if (title && ![title length])
        {
            title = nil;
        }
    }

    return title;
}

- (void) rdeGSGlue_SetTitleOfColumnZero: (NSString *) title
{
    [self setTitle: title ofColumn: 0];
}

@end

#endif  // GNUSTEP

