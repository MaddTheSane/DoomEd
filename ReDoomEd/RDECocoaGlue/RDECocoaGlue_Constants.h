/*
    RDECocoaGlue_Constants.h

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
#import <fcntl.h>


#ifndef TRUE
#   define TRUE                     true
#endif

#ifndef FALSE
#   define FALSE                    false
#endif

#ifndef MAXFLOAT
#   define MAXFLOAT                 FLT_MAX
#endif

#define NX_RETAINED                 NSBackingStoreRetained

#define NX_RGBColorSpace            NSCalibratedRGBColorSpace

#define NX_TwelveBitRGBDepth        0

#define NX_WHITE                    (1.0) // NX_WHITE must evaluate at compile-time (buildbsp.m)
#define NX_LTGRAY                   NSLightGray
#define NX_DKGRAY                   NSDarkGray
#define NX_BLACK                    NSBlack

#define NX_COPY                     NSCompositeCopy
#define NX_SOVER                    NSCompositeSourceOver

#define NX_ALERTDEFAULT             NSAlertDefaultReturn
#define NX_ALERTALTERNATE           NSAlertAlternateReturn

#define NX_RUNABORTED               NSModalResponseAbort

#define NXLocalHandler              NSLocalHandler

#define NX_READONLY                 O_RDONLY

#define NX_FREEBUFFER               1

#define NX_TITLEDSTYLE              NSTitledWindowMask
#define NX_RESIZEBARSTYLE           (NSResizableWindowMask | NSTitledWindowMask)
#define NX_MINIATURIZEBUTTONMASK    NSMiniaturizableWindowMask
#define NX_CLOSEBUTTONMASK          NSClosableWindowMask

#define NX_BUFFERED                 NSBackingStoreBuffered

#define NX_WIDTHSIZABLE             NSViewWidthSizable
#define NX_HEIGHTSIZABLE            NSViewHeightSizable

#define NX_MOUSEDRAGGEDMASK         NSLeftMouseDraggedMask
#define NX_MOUSEUP                  NSLeftMouseUp
#define NX_MOUSEUPMASK              NSLeftMouseUpMask

// OS X still defines some NeXTSTEP constants (<IOKit/IOLLEvent.h>)
#ifndef NX_SHIFTMASK
#   define NX_SHIFTMASK             NSShiftKeyMask
#endif

#ifndef NX_MOUSEMOVEDMASK
#   define NX_MOUSEMOVEDMASK        NSMouseMovedMask
#endif

#ifndef NX_LMOUSEDOWNMASK
#   define NX_LMOUSEDOWNMASK        NSLeftMouseDownMask
#endif

#ifndef NX_LMOUSEDRAGGEDMASK
#   define NX_LMOUSEDRAGGEDMASK     NSLeftMouseDraggedMask
#endif

#ifndef NX_LMOUSEUP
#   define NX_LMOUSEUP              NSLeftMouseUp
#endif

#ifndef NX_LMOUSEUPMASK
#   define NX_LMOUSEUPMASK          NSLeftMouseUpMask
#endif

#ifndef NX_RMOUSEDRAGGEDMASK
#   define NX_RMOUSEDRAGGEDMASK     NSRightMouseDraggedMask
#endif

#ifndef NX_RMOUSEUP
#   define NX_RMOUSEUP              NSRightMouseUp
#endif

#ifndef NX_RMOUSEUPMASK
#   define NX_RMOUSEUPMASK          NSRightMouseUpMask
#endif
