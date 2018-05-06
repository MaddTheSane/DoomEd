
// NeXTStep included a class called 'Storage' that implemented an array
// able to store arbitrary C types and structs. It seems that it was
// removed or otherwise ditched during the evolution towards Cocoa and
// OS X. There is some documentation about it here:
//
// http://www.cilinder.be/docs/next/NeXTStep/3.3/nd/GeneralRef/03_Common/Classes/Storage.htmld/index.html
//
// The DoomEd code makes heavy use of this class all over the place, and
// it's easier as a stopgap to just reimplement it as 'CompatibleStorage'
// rather than converting all the code to use something like NSArray. In
// the longterm the code probably should be converted or migrated to
// something sane though.

#include <stdlib.h>
#include <string.h>

#import "Storage.h"

@implementation CompatibleStorage

- (void) addElement:(void *)anElement
{
	// Equivalent to insert at the end:
	[self insertElement: anElement at: elements];
}

@synthesize count=elements;

- (const char *)description
{
	return description;
}

- (void *)elementAt:(NSUInteger)index
{
	if (index >= elements)
	{
		return NULL;
	}

	return data + elementSize * index;
}

- (void) empty
{
	elements = 0;
}

- (void) dealloc
{
	free(data);
	data = NULL;
	[super dealloc];
}

- (CompatibleStorage *) initCount: (NSUInteger)count
					  elementSize: (NSUInteger) sizeInBytes
					  description: (const char *) string
{
	if (self = [super init]) {
	description = string;
	elementSize = sizeInBytes;

	elements = count;
	data = calloc(count, sizeInBytes);
	}

	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	CompatibleStorage *newStore = [[CompatibleStorage alloc] initCount:elements elementSize:elementSize description:description];
	memcpy(newStore->data, data, elementSize * elements);
	return newStore;
}

- (void) insertElement:(void *)anElement at:(NSUInteger)index
{
	// Sanity check insert range; a maximum value of 'elements' is
	// okay to insert at the end of the array.
	if (index > elements)
	{
		return;
	}

	// Increase array size and move the latter part of the array
	// down by one.
	data = realloc(data, elementSize * (elements + 1));
	memmove(data + elementSize * (index + 1),
	        data + elementSize * index,
	        elementSize * (elements - index));

	// Copy in the new element.
	memmove(data + elementSize * index, anElement, elementSize);
	++elements;
}

- (void) removeElementAt:(NSUInteger)index
{
	if (index >= elements)
	{
		return;
	}

	// Move latter half of array down towards the start, and decrement
	// the array size.
	memmove(data + elementSize * index,
	        data + elementSize * (index + 1),
	        elementSize * (elements - index - 1));
	--elements;
}

- (void) replaceElementAt:(NSUInteger)index with:(void *)anElement
{
	if (index >= elements)
	{
		return;
	}

	memmove(data + elementSize * index, anElement, elementSize);
}

@end

