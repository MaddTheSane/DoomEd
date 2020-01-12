/*
    RDECocoaGlue_NXImage.m

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

#import "RDECocoaGlue_NXImage.h"


@implementation NSImage (RDECocoaGlue_NXImageMethods)

- (id) initSize: (NSSize *) aSize
{
    return [self initWithSize: *aSize];
}

- (id) composite: (int) operation toPoint: (const NSPoint *) pointPtr
{
    [self drawAtPoint: *pointPtr fromRect: NSZeroRect operation: operation fraction: 1.0];

    return self;
}

- (BOOL) useRepresentation: (NSImageRep *) imageRep
{
    BOOL returnVal = NO;

    if (imageRep)
    {
        [self addRepresentation: imageRep];
        returnVal = YES;
    }

    return returnVal;
}

- (id) setScalable: (BOOL) flag
{
    [self setScalesWhenResized: flag];

    return self;
}

- (BOOL) useCacheWithDepth: (int) depth
{
    return YES;
}

- (BOOL) lockFocusOn: (NSImageRep *) imageRep
{
    [self lockFocus];

    return YES;
}

- (NSImageRep *) lastRepresentation
{
    return [self bestRepresentationForDevice: nil];
}

- (id) getSize: (NSSize *) theSize
{
    *theSize = [self size];

    return self;
}

@end

