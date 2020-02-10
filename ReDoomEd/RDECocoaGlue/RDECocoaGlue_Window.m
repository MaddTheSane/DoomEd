/*
    RDECocoaGlue_Window.m

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

#import "RDECocoaGlue_Window.h"


@implementation NSWindow (RDECocoaGlue_WindowMethods)

- (id) initContent: (const NSRect *) contentRectPtr
        style: (NSUInteger) styleMask
        backing: (NSBackingStoreType) backingStoreType
        buttonMask: (NSUInteger) buttonMask
        defer: (BOOL) flag
{
    return [self initWithContentRect: *contentRectPtr
                    styleMask: styleMask | buttonMask
                    backing: backingStoreType
                    defer: flag];
}

- (NSEventMask) setEventMask: (NSEventMask) mask
{
    // only need to support mouseMoved events
    NSEventMask oldMask = ([self acceptsMouseMovedEvents]) ? NSEventMaskMouseMoved : 0;

    mask &= NSEventMaskMouseMoved;

    if (mask != oldMask)
    {
        [self setAcceptsMouseMovedEvents: (mask) ? YES : NO];
    }

    return oldMask;
}

- (NSEventMask) addToEventMask: (NSEventMask) mask
{
    // only need to support mouseMoved events
    NSEventMask oldMask = ([self acceptsMouseMovedEvents]) ? NSEventMaskMouseMoved : 0;

    mask &= NSEventMaskMouseMoved;

    if (!oldMask && mask)
    {
        [self setAcceptsMouseMovedEvents: YES];
    }

    return oldMask;
}

- (id) disableDisplay
{
    return self;
}

- (id) reenableDisplay
{
    return self;
}

- (id) reenableFlushWindow
{
    [self enableFlushWindow];

    return self;
}

- (id) setAvoidsActivation: (BOOL) flag
{
    return self;
}

- (id) setTitleAsFilename: (const char *) aString
{
    NSString *fullName = RDE_NSStringFromCString(aString);
    NSString *filename = [fullName lastPathComponent];

    [self setRepresentedURL:[NSURL fileURLWithPath:fullName]];
    [self setTitle: filename];

    return self;
}

@end

