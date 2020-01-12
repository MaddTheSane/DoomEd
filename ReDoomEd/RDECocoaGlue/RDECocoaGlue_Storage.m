/*
    RDECocoaGlue_Storage.m

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

#import "RDECocoaGlue_Storage.h"


#define kMinNumberOfAllocatedElements   10

#define kDataUpsizingRatio              (1.5)


@implementation Storage

- (id) initCount: (unsigned int) count
        elementSize: (unsigned int) sizeInBytes
        description: (char *) string
{
    self = [super init];

    if (!self)
        goto ERROR;

    if (!sizeInBytes)
        goto ERROR;

    _elementSize = sizeInBytes;
    _numElements = count;
    _maxNumElements = MAX(count, kMinNumberOfAllocatedElements);

    _dataPtr = calloc(_maxNumElements, sizeInBytes);

    if (!_dataPtr)
        goto ERROR;

    return self;

ERROR:
    [self release];

    return nil;
}

- (void) dealloc
{
    if (_dataPtr)
    {
        free(_dataPtr);
    }

    [super dealloc];
}

- (NSUInteger) count
{
    return _numElements;
}

- (void *) elementAt: (unsigned int) index
{
    if (index >= _numElements)
    {
        goto ERROR;
    }

    return (void *) &(_dataPtr[index * _elementSize]);

ERROR:
    return NULL;
}

- (id) addElement: (void *) anElement
{
    return [self insertElement: anElement at: _numElements];
}

- (id) insertElement: (void *) anElement at: (unsigned int) index
{
    unsigned char *storageElement;

    if (index > _numElements)
    {
        goto ERROR;
    }

    if (_numElements >= _maxNumElements)
    {
        unsigned int newMaxNumElements = (unsigned int) (kDataUpsizingRatio * _numElements);
        unsigned char *reallocatedDataPtr = realloc(_dataPtr, newMaxNumElements * _elementSize);

        if (!reallocatedDataPtr)
            goto ERROR;

        _dataPtr = reallocatedDataPtr;
        _maxNumElements = newMaxNumElements;
    }

    storageElement = &_dataPtr[index * _elementSize];

    if (index < _numElements)
    {
        memmove(&storageElement[_elementSize], storageElement,
                (_numElements - index) * _elementSize);
    }

    memmove(storageElement, anElement, _elementSize);
    _numElements++;

    return self;

ERROR:
    return self;
}

- (id) replaceElementAt: (unsigned int) index with: (void *) anElement
{
    unsigned char *storageElement;

    if (index >= _numElements)
    {
        goto ERROR;
    }

    storageElement = &_dataPtr[index * _elementSize];

    memmove(storageElement, anElement, _elementSize);

    return self;

ERROR:
    return self;
}

- (id) removeElementAt: (unsigned int) index
{
    unsigned char *element;

    if (index >= _numElements)
    {
        goto ERROR;
    }

    if (index < (_numElements-1))
    {
        element = &_dataPtr[index * _elementSize];

        memmove(element, &element[_elementSize], (_numElements - 1 - index) * _elementSize);
    }

    _numElements--;

    return self;

ERROR:
    return self;
}

- (id) empty
{
    _numElements = 0;

    if (_maxNumElements > kMinNumberOfAllocatedElements)
    {
        unsigned char *reallocatedDataPtr =
                            realloc(_dataPtr, kMinNumberOfAllocatedElements * _elementSize);

        if (!reallocatedDataPtr)
            goto ERROR;

        _dataPtr = reallocatedDataPtr;
        _maxNumElements = kMinNumberOfAllocatedElements;
    }

    return self;

ERROR:
    return self;
}

@end

