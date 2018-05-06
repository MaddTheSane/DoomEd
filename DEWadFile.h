#import "Storage.h"

#import <AppKit/AppKit.h>

@class DELumpInfo;

@interface DEWadFile : NSObject
{
	int					handle;
	NSString			*pathname;
	NSMutableArray<DELumpInfo*> 	*info;
	BOOL				dirty;
}

- (instancetype)initWithFilePath: (NSString *)path;
- (instancetype)initNewWithPath: (NSString *)path;
- (void)close;

@property (readonly) NSInteger countOfLumps;
- (int)sizeOfLumpAtIndex: (NSInteger)lump;
- (int)startOfLumpAtIndex: (NSInteger)lump;
- (NSString *)nameOfLumpAtIndex: (NSInteger)lump;
- (NSInteger)indexOfLumpNamed: (NSString *)name;
- (NSData *)dataOfLumpAtIndex: (NSInteger)lump;
- (NSData *)dataOfLumpNamed: (NSString *)name;

- (void)addIndexWithName: (NSString *)name data: (NSData *)data;
- (void)writeDirectory;

@end

@interface DELumpInfo: NSObject
@property int filePosition;
@property int dataSize;
@property (copy) NSString *name;
@end
