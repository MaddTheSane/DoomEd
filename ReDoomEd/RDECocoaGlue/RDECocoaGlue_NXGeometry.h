/*
    RDECocoaGlue_NXGeometry.h

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
#import "RDECocoaGlue_Macros.h"


#define NXRect  NSRect
#define NXPoint NSPoint
#define NXSize  NSSize


static inline void NXSetRect(NSRect *rectPtr, float originX, float originY, float width, float height) RDE_DEPRECATED("Use NSMakeRect instead", macos(10.0,10.0));
static inline void NXSetRect(NSRect *rectPtr, float originX, float originY, float width, float height) {
    *(rectPtr) = NSMakeRect(originX, originY, width, height);
}

static inline void NXUnionRect(const NSRect *rectPtr, NSRect *otherRectPtr) RDE_DEPRECATED("Use NSUnionRect instead", macos(10.0,10.0));
static inline void NXUnionRect(const NSRect *rectPtr, NSRect *otherRectPtr) {
    *(otherRectPtr) = NSUnionRect(*(rectPtr), *(otherRectPtr));
}

static inline BOOL NXIntersectsRect(NSRect *rectPtr, NSRect *otherRectPtr) RDE_DEPRECATED("Use NSIntersectsRect instead", macos(10.0,10.0));
static inline BOOL NXIntersectsRect(NSRect *rectPtr, NSRect *otherRectPtr) {
    return NSIntersectsRect(*(rectPtr), *(otherRectPtr));
}

static inline void NXIntegralRect(NSRect *rectPtr) RDE_DEPRECATED("Use NSIntegralRect instead", macos(10.0,10.0));
static inline void NXIntegralRect(NSRect *rectPtr) {
    *(rectPtr) = NSIntegralRect(*(rectPtr));
}

static inline BOOL NXPointInRect(NSPoint *rectPtr, NSRect *pointPtr) RDE_DEPRECATED("Use NSPointInRect instead", macos(10.0,10.0));
static inline BOOL NXPointInRect(NSPoint *rectPtr, NSRect *pointPtr) {
    return NSPointInRect(*(rectPtr), *(pointPtr));
}
