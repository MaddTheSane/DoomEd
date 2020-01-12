/*
    RDEGNUstepGlue_MouseDragging.m

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
// Better responsiveness on GNUstep when dragging the mouse on the MapView:
// Patched -[RDEApplication nextEventMatchingMask:...] to skip to the most recent mouseDragged
// event in the queue (discarding the rest), which saves having to redraw the map view for each
// (out-of-date) mouseDragged location.

#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"
#import "../RDEApplication.h"


@interface NSEvent (RDEGNUstepGlue_MouseDraggingUtilities)

- (NSEvent *) rdeGSGlue_LatestMouseDraggedEventFromEventQueue;

@end

@implementation NSObject (RDEGNUstepGlue_MouseDragging)

+ (void) rdeGSGlue_MouseDragging_InstallPatches
{
    macroSwizzleInstanceMethod(RDEApplication, nextEventMatchingMask:untilDate:inMode:dequeue:,
                                rdeGSPatch_NextEventMatchingMask:untilDate:inMode:dequeue:);
}

+ (void) load
{
    macroPerformNSObjectSelectorAfterAppLoads(rdeGSGlue_MouseDragging_InstallPatches);
}

@end

@implementation RDEApplication (RDEGNUstepGlue_MouseDragging)

- (NSEvent *) rdeGSPatch_NextEventMatchingMask: (NSUInteger) mask
                untilDate: (NSDate *) expiration
                inMode: (NSString *) mode
                dequeue: (BOOL) shouldDequeue
{
    static int recursionLevel = 0;
    NSEvent *returnedEvent = [self rdeGSPatch_NextEventMatchingMask: mask
                                    untilDate: expiration
                                    inMode: mode
                                    dequeue: shouldDequeue];    

    if ((mask & NSLeftMouseDraggedMask)
        && (recursionLevel == 0)
        && shouldDequeue
        && ([returnedEvent type] == NSLeftMouseDragged))
    {
        // -[NSEvent rdeGSGlue_LatestMouseDraggedEventFromEventQueue] calls back to this method,
        // so keep track of the recursion level to prevent recursing more than once
        recursionLevel++;

        returnedEvent = [returnedEvent rdeGSGlue_LatestMouseDraggedEventFromEventQueue];

        recursionLevel--;
    }

    return returnedEvent;
}

@end

@implementation NSEvent (RDEGNUstepGlue_MouseDraggingUtilities)

- (NSEvent *) rdeGSGlue_LatestMouseDraggedEventFromEventQueue
{
    NSEvent *dequeuedEvent, *lastMouseDraggedEvent;

    if ([self type] != NSLeftMouseDragged)
    {
        goto ERROR;
    }

    dequeuedEvent = lastMouseDraggedEvent = self;

    while (dequeuedEvent)
    {
        lastMouseDraggedEvent = dequeuedEvent;

        dequeuedEvent =
                [NSApp nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask
                        untilDate: nil
                        inMode: NSEventTrackingRunLoopMode
                        dequeue: YES];

        if ([dequeuedEvent type] == NSLeftMouseUp)
        {
            [NSApp postEvent: dequeuedEvent atStart: YES];

            dequeuedEvent = nil;
        }
    }

    return lastMouseDraggedEvent;

ERROR:
    return self;
}

@end

