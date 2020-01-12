/*
    RDEGNUstepGlue_MenuActivatedModalSessions.m

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
//  Workaround for a GNUstep issue where selecting a submenu item that opens a modal panel can
// cause the submenu window to remain visible until after the modal session finishes;
//  The fix is to add a short delay (until a new stackframe) before sending the menu item's
// action (on the menu items that can start modal sessions), so the submenu window has a
// chance to hide before the modal session begins

#ifdef GNUSTEP

#import <Cocoa/Cocoa.h>
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"


#define kDelayedMenuItemActionNames                                                         \
            @"openProject:", @"newProject:", @"printStatistics:", @"loadAndSaveAllMaps:",   \
            @"saveDoomEdMapBSP:", @"saveWorld:", @"printSingleMapStatistics:",              \
            @"printMap:", @"printAllMaps:", @"print:"


static NSSet *DelayedMenuItemsSet(void);


@interface NSMenu (RDEGNUstepGlue_MenuActivatedModalSessionsUtilities)

- (void) rdeGSGlue_PerformActionForItemAtIndexNumber: (NSNumber *) indexNumber;

@end

@implementation NSObject (RDEGNUstepGlue_MenuActivatedModalSessions)

+ (void) rdeGSGlue_MenuActivatedModalSessions_InstallPatches
{
    macroSwizzleInstanceMethod(NSMenu, performActionForItemAtIndex:,
                                rdeGSPatch_performActionForItemAtIndex:);
}

+ (void) load
{
    macroPerformNSObjectSelectorAfterAppLoads(
                                        rdeGSGlue_MenuActivatedModalSessions_InstallPatches);
}

@end

@implementation NSMenu (RDEGNUstepGlue_MenuActivatedModalSessions)

- (void) rdeGSPatch_performActionForItemAtIndex: (NSInteger) index
{
    static NSSet *delayedMenuItemsSet = nil;
    NSMenuItem *menuItem;

    if (!delayedMenuItemsSet)
    {
        delayedMenuItemsSet = [DelayedMenuItemsSet() retain];
    }

    menuItem = [self itemAtIndex: index];

    if (menuItem && [delayedMenuItemsSet containsObject: menuItem])
    {
        NSNumber *indexNumber = [NSNumber numberWithInt: index];

        if (indexNumber)
        {
            [self performSelector: @selector(rdeGSGlue_PerformActionForItemAtIndexNumber:)
                    withObject: indexNumber
                    afterDelay: 0.0];

            return;
        }
    }

    [self rdeGSPatch_performActionForItemAtIndex: index];
}

- (void) rdeGSGlue_PerformActionForItemAtIndexNumber: (NSNumber *) indexNumber
{
    if (!indexNumber)
        return;

    [self rdeGSPatch_performActionForItemAtIndex: [indexNumber intValue]];
}

@end

static NSSet *DelayedMenuItemsSet(void)
{
    NSSet *delayedActionNamesSet;
    NSMutableSet *delayedItemsSet;
    NSMutableArray *menus;
    int menuIndex;
    NSMenu *menu;
    NSEnumerator *menuItemEnumerator;
    NSMenuItem *menuItem;
    SEL action;
    NSString *actionName;
 
    delayedActionNamesSet = [NSSet setWithObjects: kDelayedMenuItemActionNames, nil];
    delayedItemsSet = [NSMutableSet set];
    menus = [NSMutableArray array];

    if (!delayedActionNamesSet || !delayedItemsSet || !menus)
    {
        goto ERROR;
    }

    // go through the menu items in the main menu & its submenus, and add the item to
    // delayedItemsSet if delayedActionNamesSet contains the item's action name

    [menus addObject: [NSApp mainMenu]];
    menuIndex = 0;

    while (menuIndex < [menus count])
    {
        menu = [menus objectAtIndex: menuIndex];

        menuItemEnumerator = [[menu itemArray] objectEnumerator];

        while (menuItem = [menuItemEnumerator nextObject])
        {
            if ([menuItem hasSubmenu])
            {
                [menus addObject: [menuItem submenu]];
            }
            else
            {
                action = [menuItem action];

                if (action)
                {
                    actionName = NSStringFromSelector(action);

                    if (actionName
                        && [delayedActionNamesSet containsObject: actionName])
                    {
                        [delayedItemsSet addObject: menuItem];
                    }
                }
            }
        }

        menuIndex++;
    }

    return [NSSet setWithSet: delayedItemsSet];

ERROR:
    return nil;
}

#endif  // GNUSTEP

