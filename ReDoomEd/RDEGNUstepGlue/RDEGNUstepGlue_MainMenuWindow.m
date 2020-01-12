/*
    RDEGNUstepGlue_MainMenuWindow.m

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
// Workarounds for GNUstep's standalone main menu window overlapping other UI elements:
// - On GNOME, the main menu's default position is too close to the screen's upper-left corner,
// and the menu becomes obscured by GNOME's menu bar (top edge) & application dock (left edge).
// - The default positions of the main menu & the tool panel can overlap

#ifdef GNUSTEP

#import <Cocoa/Cocoa.h>
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"
#import "PPGNUstepGlueUtilities.h"
#import "../DoomEd/Coordinator.h"


#define kMinMarginForGNOMEMainMenu_Horizontal       75
#define kMinMarginForGNOMEMainMenu_Vertical         35

#define kMinDistanceBetweenToolPanelAndMainMenu     20


@interface Coordinator (RDEGNUstepGlue_MainMenuWindowUtilities)

- (void) rdeGSUtil_FixGNOMEMainMenuOverlap;

- (void) rdeGSUtil_FixToolPanelMainMenuOverlap;

@end

@implementation NSObject (RDEGNUstepGlue_MainMenuWindow)

+ (void) rdeGSGlue_MainMenuWindow_InstallPatches
{
    macroSwizzleInstanceMethod(Coordinator, applicationDidFinishLaunching:,
                                rdeGSPatch_ApplicationDidFinishLaunching:);
}

+ (void) load
{
    macroPerformNSObjectSelectorAfterAppLoads(rdeGSGlue_MainMenuWindow_InstallPatches);
}

@end

@implementation Coordinator (RDEGNUstepGlue_MainMenuWindow)

- (void) rdeGSPatch_ApplicationDidFinishLaunching: (NSNotification *) notification
{
    [self rdeGSPatch_ApplicationDidFinishLaunching: notification];

    [self rdeGSUtil_FixGNOMEMainMenuOverlap];

    [self rdeGSUtil_FixToolPanelMainMenuOverlap];
}

- (void) rdeGSUtil_FixGNOMEMainMenuOverlap
{
    NSString *interfaceStyleName;
    NSWindow *mainMenuWindow;
    NSRect mainMenuWindowFrame, screenVisibleFrame;
    bool shouldUpdateMainMenuWindowOrigin = NO;

    // return if not running on GNOME (Mutter WM)
    if (!PPGSGlueUtils_WindowManagerMatchesTypeMask(kPPGSWindowManagerTypeMask_Mutter))
    {
        return;
    }

    // return if not using NeXTSTEP interface style (no standalone main menu window)
    interfaceStyleName =
        [[NSUserDefaults standardUserDefaults] objectForKey: @"NSInterfaceStyleDefault"];

    if (interfaceStyleName
        && ![interfaceStyleName isEqualToString: @"NSNextStepInterfaceStyle"])
    {
        return;
    }

    mainMenuWindow = [[NSApp mainMenu] window];

    if (![mainMenuWindow isVisible])
    {
        return;
    }

    mainMenuWindowFrame = [mainMenuWindow frame];
    screenVisibleFrame = [[mainMenuWindow screen] visibleFrame];

    if (!NSIsEmptyRect(screenVisibleFrame))
    {
        CGFloat maxYOrigin = NSMaxY(screenVisibleFrame)
                                - kMinMarginForGNOMEMainMenu_Vertical
                                - mainMenuWindowFrame.size.height;

        if (mainMenuWindowFrame.origin.y > maxYOrigin)
        {
            mainMenuWindowFrame.origin.y = maxYOrigin;
            shouldUpdateMainMenuWindowOrigin = YES;
        }
    }

    if ((mainMenuWindowFrame.origin.x >= 0)
        && (mainMenuWindowFrame.origin.x < kMinMarginForGNOMEMainMenu_Horizontal))
    {
        mainMenuWindowFrame.origin.x = kMinMarginForGNOMEMainMenu_Horizontal;
        shouldUpdateMainMenuWindowOrigin = YES;
    }

    if (shouldUpdateMainMenuWindowOrigin)
    {
        [mainMenuWindow setFrameOrigin: mainMenuWindowFrame.origin];
    }
}

- (void) rdeGSUtil_FixToolPanelMainMenuOverlap
{
    NSWindow *toolPanel;
    NSRect toolPanelFrame, mainMenuFrame, mainMenuFrameMargin;

    toolPanel = (NSWindow *) toolPanel_i;
    toolPanelFrame = [toolPanel frame];
    mainMenuFrame = [[[NSApp mainMenu] window] frame];
    mainMenuFrameMargin = NSInsetRect(mainMenuFrame, -kMinDistanceBetweenToolPanelAndMainMenu,
                                        -kMinDistanceBetweenToolPanelAndMainMenu);

    if (!NSIsEmptyRect(NSIntersectionRect(toolPanelFrame, mainMenuFrameMargin)))
    {
        toolPanelFrame.origin.y = NSMinY(mainMenuFrameMargin) - toolPanelFrame.size.height;
        [toolPanel setFrameOrigin: toolPanelFrame.origin];
    }
}

@end

#endif  // GNUSTEP

