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

@end

@interface RDEPatchDividerObject : NSObject
@property int x;
@property int y;
@property (copy) NSString *string;
@end

NS_ASSUME_NONNULL_END
