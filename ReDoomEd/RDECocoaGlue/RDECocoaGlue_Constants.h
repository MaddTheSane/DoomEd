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
#import "RDECocoaGlue_Macros.h"


#ifndef TRUE
#   define TRUE                     true
#endif

#ifndef FALSE
#   define FALSE                    false
#endif

#ifndef MAXFLOAT
#   define MAXFLOAT                 FLT_MAX
#endif

static const NSBackingStoreType NX_RETAINED RDE_DEPRECATED_WITH_REPLACEMENT("NSBackingStoreRetained", macos(10.0,10.0)) = NSBackingStoreRetained;
static const NSBackingStoreType NX_BUFFERED RDE_DEPRECATED_WITH_REPLACEMENT("NSBackingStoreBuffered", macos(10.0,10.0)) = NSBackingStoreBuffered;

#define NX_RGBColorSpace            NSCalibratedRGBColorSpace

#define NX_TwelveBitRGBDepth        0

#define NX_WHITE                    (1.0) // NX_WHITE must evaluate at compile-time (buildbsp.m)
#define NX_LTGRAY                   NSLightGray
#define NX_DKGRAY                   NSDarkGray
#define NX_BLACK                    NSBlack

static const NSCompositingOperation NX_COPY RDE_DEPRECATED_WITH_REPLACEMENT("NSCompositingOperationCopy", macos(10.0,10.0)) = NSCompositingOperationCopy;
static const NSCompositingOperation NX_SOVER RDE_DEPRECATED_WITH_REPLACEMENT("NSCompositingOperationSourceOver", macos(10.0,10.0)) = NSCompositingOperationSourceOver;

static const NSInteger NX_ALERTDEFAULT RDE_DEPRECATED_WITH_REPLACEMENT("NSAlertDefaultReturn", macos(10.0,10.0)) = NSAlertDefaultReturn;
static const NSInteger NX_ALERTALTERNATE RDE_DEPRECATED_WITH_REPLACEMENT("NSAlertAlternateReturn", macos(10.0,10.0)) = NSAlertAlternateReturn;

static const NSModalResponse NX_RUNABORTED RDE_DEPRECATED_WITH_REPLACEMENT("NSModalResponseAbort", macos(10.0,10.0)) = NSModalResponseAbort;

#define NXLocalHandler              NSLocalHandler

#define NX_READONLY                 O_RDONLY

#define NX_FREEBUFFER               1

static const NSWindowStyleMask NX_TITLEDSTYLE RDE_DEPRECATED_WITH_REPLACEMENT("NSWindowStyleMaskTitled", macos(10.0,10.0)) = NSWindowStyleMaskTitled;

static const NSWindowStyleMask NX_RESIZEBARSTYLE RDE_DEPRECATED_WITH_REPLACEMENT("(NSWindowStyleMaskResizable | NSWindowStyleMaskTitled)", macos(10.0,10.0)) = (NSWindowStyleMaskResizable | NSWindowStyleMaskTitled);
static const NSWindowStyleMask NX_MINIATURIZEBUTTONMASK RDE_DEPRECATED_WITH_REPLACEMENT("NSWindowStyleMaskMiniaturizable", macos(10.0,10.0)) = NSWindowStyleMaskMiniaturizable;
static const NSWindowStyleMask NX_CLOSEBUTTONMASK RDE_DEPRECATED_WITH_REPLACEMENT("NSWindowStyleMaskClosable", macos(10.0,10.0)) = NSWindowStyleMaskClosable;

static const NSAutoresizingMaskOptions NX_WIDTHSIZABLE RDE_DEPRECATED_WITH_REPLACEMENT("NSViewWidthSizable", macos(10.0,10.0)) = NSViewWidthSizable;
static const NSAutoresizingMaskOptions NX_HEIGHTSIZABLE RDE_DEPRECATED_WITH_REPLACEMENT("NSViewHeightSizable", macos(10.0,10.0)) = NSViewHeightSizable;

static const NSEventMask NX_MOUSEDRAGGEDMASK RDE_DEPRECATED_WITH_REPLACEMENT("NSEventMaskLeftMouseDragged", macos(10.0,10.0)) = NSEventMaskLeftMouseDragged;
static const NSEventType NX_MOUSEUP RDE_DEPRECATED_WITH_REPLACEMENT("NSEventTypeLeftMouseUp", macos(10.0,10.0)) = NSEventTypeLeftMouseUp;
static const NSEventMask NX_MOUSEUPMASK RDE_DEPRECATED_WITH_REPLACEMENT("NSEventMaskLeftMouseUp", macos(10.0,10.0)) = NSEventMaskLeftMouseUp;

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
