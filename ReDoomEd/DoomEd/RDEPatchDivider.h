//
//  RDEPatchDivider.h
//  ReDoomEd
//
//  Created by C.W. Betts on 2/9/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RDEPatchDivider <NSObject>
/// Add a Patch Palette divider (new set of patches)
- (void)addDividerX:(NSInteger)x y:(NSInteger)y string:(NSString *)string NS_SWIFT_NAME(addDivider(x:y:string:));

/// Dump all the dividers (for resizing)
- (void)dumpDividers;

@optional
- (void)addDividerX:(int)x Y:(int)y String:(const char *__null_unspecified)string DEPRECATED_ATTRIBUTE;
@end

@interface RDEPatchDividerObject : NSObject
@property int x;
@property int y;
@property (copy) NSString *string;
@end

NS_ASSUME_NONNULL_END
