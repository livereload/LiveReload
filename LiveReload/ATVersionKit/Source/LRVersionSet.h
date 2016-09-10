
#import <Foundation/Foundation.h>


@class LRVersion;
@class LRVersionRange;
@class LRVersionSpace;


NS_ASSUME_NONNULL_BEGIN

@interface LRVersionSet : NSObject

+ (instancetype)emptyVersionSet;
+ (instancetype)emptyVersionSetWithError:(nullable NSError *)error;
+ (instancetype)allVersionsSet;
+ (instancetype)versionSetWithRanges:(NSArray<LRVersionRange *> *)ranges;
+ (instancetype)versionSetWithRange:(LRVersionRange *)range;
+ (instancetype)versionSetWithVersion:(LRVersion *)version;

- (BOOL)containsVersion:(LRVersion *)version;

@property(nonatomic, readonly, getter=isValid) BOOL valid;
@property(nonatomic, readonly, nullable) NSError *error;

// currently, this is not always available
@property(nonatomic, readonly, nullable) LRVersionSpace *versionSpace;

@end

NS_ASSUME_NONNULL_END
