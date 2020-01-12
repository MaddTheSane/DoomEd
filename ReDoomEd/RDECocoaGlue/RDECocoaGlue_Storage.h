/*
    RDECocoaGlue_Storage.h

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


@interface Storage : NSObject
{
    unsigned char *_dataPtr;
    unsigned int _numElements;
    unsigned int _maxNumElements;
    unsigned int _elementSize;
}

- (id) initCount: (unsigned int) count
        elementSize: (unsigned int) sizeInBytes
        description: (char *) string;

- (NSUInteger) count;

- (void *) elementAt: (unsigned int) index;

- (id) addElement: (void *) anElement;

- (id) insertElement: (void *) anElement at: (unsigned int) index;

- (id) replaceElementAt: (unsigned int) index with: (void *) anElement;

- (id) removeElementAt: (unsigned int) index;

- (id) empty;

@end

