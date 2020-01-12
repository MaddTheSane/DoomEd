/*
    RDECocoaGlue_PanelUtilities.m

    Copyright 2019 Josh Freeman
    http://www.twilightedge.com

    This file is part of ReDoomEd for Mac OS X and GNUstep. ReDoomEd is a Doom game map
    editor, ported from id Software's DoomEd for NeXTSTEP.

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

#import "RDECocoaGlue_PanelUtilities.h"


NSControl *gActiveTextControl = nil;
bool gShouldTrackActiveTextControl = NO, gActiveTextDidChange = NO;


@interface NSApplication (RDECocoaGlue_PanelUtilitiesPrivateMethods)

- (void) addAsObserverForTextEditingNotificationsForPanel: (NSPanel *) panel;

- (void) handleNSWindowNotification_DidBecomeKey: (NSNotification *) notification;
- (void) handleNSWindowNotification_DidResignKey: (NSNotification *) notification;

- (void) handleNSTextNotification_DidBeginEditing: (NSNotification *) notification;
- (void) handleNSTextNotification_DidChange: (NSNotification *) notification;
- (void) handleNSTextNotification_DidEndEditing: (NSNotification *) notification;

- (void) setupActiveTextGlobalsWithFieldEditor: (NSTextView *) fieldEditor;
- (void) clearActiveTextGlobals;

@end

@implementation NSPanel (RDECocoaGlue_PanelUtilities)

- (void) rdeSetupTextfieldsToSendActionWhenPanelResignsKey
{
    [NSApp addAsObserverForTextEditingNotificationsForPanel: self];
}

@end

@implementation NSApplication (RDECocoaGlue_PanelUtilitiesPrivateMethods)

- (void) addAsObserverForTextEditingNotificationsForPanel: (NSPanel *) panel
{
    static bool didAddAsObserverForNSTextNotifications = NO;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    if (!panel)
        return;

    if (!didAddAsObserverForNSTextNotifications)
    {

        [notificationCenter addObserver: self
                            selector: @selector(handleNSTextNotification_DidBeginEditing:)
                            name: NSTextDidBeginEditingNotification
                            object: nil];

        [notificationCenter addObserver: self
                            selector: @selector(handleNSTextNotification_DidChange:)
                            name: NSTextDidChangeNotification
                            object: nil];

        [notificationCenter addObserver: self
                            selector: @selector(handleNSTextNotification_DidEndEditing:)
                            name: NSTextDidEndEditingNotification
                            object: nil];

        didAddAsObserverForNSTextNotifications = YES;
    }

    [notificationCenter addObserver: self
                        selector: @selector(handleNSWindowNotification_DidBecomeKey:)
                        name: NSWindowDidBecomeKeyNotification
                        object: panel];

    [notificationCenter addObserver: self
                        selector: @selector(handleNSWindowNotification_DidResignKey:)
                        name: NSWindowDidResignKeyNotification
                        object: panel];

    if ([panel isKeyWindow])
    {
        [self handleNSWindowNotification_DidBecomeKey: nil];
    }
}

- (void) handleNSWindowNotification_DidBecomeKey: (NSNotification *) notification
{
    NSWindow *window;
    NSResponder *firstResponder;

    gShouldTrackActiveTextControl = YES;

    window = [notification object];
    firstResponder = [window firstResponder];

    if (firstResponder
        && [firstResponder isKindOfClass: [NSTextView class]]
        && [((NSTextView *) firstResponder) isFieldEditor])
    {
        [self setupActiveTextGlobalsWithFieldEditor: (NSTextView *) firstResponder];
    }
}

- (void) handleNSWindowNotification_DidResignKey: (NSNotification *) notification
{
    gShouldTrackActiveTextControl = NO;

    if (gActiveTextControl)
    {
        if (gActiveTextDidChange)
        {
            [gActiveTextControl sendAction: [gActiveTextControl action]
                                to: [gActiveTextControl target]];
        }

        [self clearActiveTextGlobals];
    }
}

- (void) handleNSTextNotification_DidBeginEditing: (NSNotification *) notification
{
    if (gShouldTrackActiveTextControl)
    {
        [self setupActiveTextGlobalsWithFieldEditor: [notification object]];
    }
}

- (void) handleNSTextNotification_DidChange: (NSNotification *) notification
{
    if (gShouldTrackActiveTextControl)
    {
        gActiveTextDidChange = YES;
    }
}

- (void) handleNSTextNotification_DidEndEditing: (NSNotification *) notification
{
    if (gShouldTrackActiveTextControl)
    {
        [self clearActiveTextGlobals];
    }
}

- (void) setupActiveTextGlobalsWithFieldEditor: (NSTextView *) fieldEditor
{
    NSControl *activeTextControl;

    [self clearActiveTextGlobals];

    activeTextControl = (NSControl *) [fieldEditor delegate];

    if (activeTextControl
        && [activeTextControl isKindOfClass: [NSControl class]]
        && ([activeTextControl target] != nil))
    {
        gActiveTextControl = [activeTextControl retain];
    }
}

- (void) clearActiveTextGlobals
{
    if (gActiveTextControl)
    {
        [gActiveTextControl release];
        gActiveTextControl = nil;
    }

    gActiveTextDidChange = NO;
}

@end
