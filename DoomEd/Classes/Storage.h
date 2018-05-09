
#import <Foundation/NSObject.h>

NS_ASSUME_NONNULL_BEGIN

/// NeXTStep included a class called 'Storage' that implemented an array
/// able to store arbitrary C types and structs. It seems that it was
/// removed or otherwise ditched during the evolution towards Cocoa and
/// OS X. There is some documentation about it here:
///
/// http://www.cilinder.be/docs/next/NeXTStep/3.3/nd/GeneralRef/03_Common/Classes/Storage.htmld/index.html
///
/// The DoomEd code makes heavy use of this class all over the place, and
/// it's easier as a stopgap to just reimplement it as 'CompatibleStorage'
/// rather than converting all the code to use something like NSArray. In
/// the longterm the code probably should be converted or migrated to
/// something sane though.
@interface CompatibleStorage:NSObject <NSCopying>
{
	uint8_t *data;
	NSUInteger elements;
	NSUInteger elementSize;
	const char *description;
}

- (void) addElement:(void *)anElement;
@property (readonly) NSUInteger count;
- (nullable const char *)description;
- (nullable void *)elementAt:(NSUInteger)index NS_RETURNS_INNER_POINTER;
- (void) empty;
- (instancetype) initCount: (NSUInteger)count
			   elementSize: (NSUInteger) sizeInBytes
			   description: (nullable const char *) string;
- (void) insertElement:(void *)anElement at:(NSUInteger)index;
- (void) removeElementAt:(NSUInteger)index;
- (void) replaceElementAt:(NSUInteger)index with:(void *)anElement;

@end

NS_ASSUME_NONNULL_END
