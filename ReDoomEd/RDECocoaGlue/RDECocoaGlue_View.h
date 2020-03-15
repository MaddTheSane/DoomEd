/*
    RDECocoaGlue_View.h

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

#import <Cocoa/Cocoa.h>


@interface View : NSView
{
}

- (id) initFrame: (const NSRect *) frameRectPtr;

@end

// View methods are implemented as an NSView category so they can also be inherited by
// ScrollView (NSScrollView) & NSScroller

@interface NSView (RDECocoaGlue_ViewMethods)

- (id) getBounds: (NSRect *) theRect API_DEPRECATED("Call -bounds instead", macos(10.0, 10.0));

- (id) getFrame: (NSRect *) theRect API_DEPRECATED("Call -frame instead", macos(10.0, 10.0));

- (BOOL) getVisibleRect: (NXRect *) theRect API_DEPRECATED("Call -visibleRect instead", macos(10.0, 10.0));

- (id) setDrawOrigin: (float) x : (float) y API_DEPRECATED("Call -setBoundsOrigin: instead", macos(10.0, 10.0));

- (id) setDrawSize: (float) width : (float) height API_DEPRECATED("Call -setBoundsSize: instead", macos(10.0, 10.0));

- (id) convertPointFromSuperview: (NSPoint *) aPoint;

- (id) convertRectFromSuperview: (NSRect *) aRect;

- (id) display: (const NSRect *) rectPtrs : (int) rectCount;

- (id) drawSelf: (const NSRect *) rectPtrs : (int) rectCount;

- (id) sizeTo: (float) width : (float) height API_DEPRECATED("Call -setFrameSize: instead", macos(10.0, 10.0));

- (id) setAutosizing: (unsigned int) mask API_DEPRECATED_WITH_REPLACEMENT("-setAutoresizingMask:", macos(10.0, 10.0));

- (id) printPSCode: (id) sender API_DEPRECATED_WITH_REPLACEMENT("-print:", macos(10.0, 10.0));

@end

