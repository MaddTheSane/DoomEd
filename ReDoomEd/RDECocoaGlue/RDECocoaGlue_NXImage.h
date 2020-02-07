/*
    RDECocoaGlue_NXImage.h

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


#define NXImage     NSImage
#define NXImageRep  NSImageRep


@interface NSImage (RDECocoaGlue_NXImageMethods)

- (id) initSize: (NSSize *) aSize API_DEPRECATED_WITH_REPLACEMENT("-initWithSize:", macos(10.0, 10.0));

- (id) composite: (NSCompositingOperation) operation toPoint: (const NSPoint *) pointPtr API_DEPRECATED("Use -drawAtPoint:fromRect:operation:fraction: instead", macos(10.0, 10.0));

- (BOOL) useRepresentation: (NSImageRep *) imageRep API_DEPRECATED_WITH_REPLACEMENT("-addRepresentation:", macos(10.0, 10.0));

- (id) setScalable: (BOOL) flag;

- (BOOL) useCacheWithDepth: (int) depth;

- (BOOL) lockFocusOn: (NSImageRep *) imageRep;

- (NSImageRep *) lastRepresentation;

- (id) getSize: (NSSize *) theSize API_DEPRECATED("Use -size instead", macos(10.0, 10.0));

@end
