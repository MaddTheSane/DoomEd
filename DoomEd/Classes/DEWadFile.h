#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DELumpInfo;

@interface DEWadFile : NSObject
{
	int					handle;
	NSString			*pathname;
	NSMutableArray<DELumpInfo*> 	*info;
	BOOL				dirty;
}

- (nullable instancetype)initWithFilePath: (NSString *)path;
- (nullable instancetype)initNewWithPath: (NSString *)path;
- (void)close;

@property (readonly) NSInteger countOfLumps;
- (int)sizeOfLumpAtIndex: (NSInteger)lump;
- (int)startOfLumpAtIndex: (NSInteger)lump;
- (NSString *)nameOfLumpAtIndex: (NSInteger)lump;
- (NSInteger)indexOfLumpNamed: (NSString *)name;
- (nullable NSData *)dataOfLumpAtIndex: (NSInteger)lump;
- (nullable NSData *)dataOfLumpNamed: (NSString *)name;

- (void)addIndexWithName: (NSString *)name data: (NSData *)data;
- (void)writeDirectory;

@end

@interface DELumpInfo: NSObject
@property int filePosition;
@property int dataSize;
@property (copy, nullable) NSString *name;
@end

NS_ASSUME_NONNULL_END
