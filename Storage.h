
#import <Foundation/NSObject.h>

@interface CompatibleStorage:NSObject <NSCopying>
{
	uint8_t *data;
	NSUInteger elements;
	NSUInteger elementSize;
	const char *description;
}

- (void) addElement:(void *)anElement;
@property (readonly) NSUInteger count;
- (const char *)description;
- (void *)elementAt:(NSUInteger)index;
- (void) empty;
- (instancetype) initCount:(NSUInteger)count
			   elementSize: (NSUInteger) sizeInBytes
			   description: (const char *) string;
- (void) insertElement:(void *)anElement at:(NSUInteger)index;
- (void) removeElementAt:(NSUInteger)index;
- (void) replaceElementAt:(NSUInteger)index with:(void *)anElement;

@end

