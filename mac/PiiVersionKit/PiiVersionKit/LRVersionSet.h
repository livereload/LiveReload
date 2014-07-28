
#import <Foundation/Foundation.h>


@class LRVersion;
@class LRVersionRange;
@class LRVersionSpace;


@interface LRVersionSet : NSObject

+ (instancetype)emptyVersionSet;
+ (instancetype)emptyVersionSetWithError:(NSError *)error;
+ (instancetype)allVersionsSet;
+ (instancetype)versionSetWithRanges:(NSArray *)ranges;
+ (instancetype)versionSetWithRange:(LRVersionRange *)range;
+ (instancetype)versionSetWithVersion:(LRVersion *)version;

- (BOOL)containsVersion:(LRVersion *)version;

@property(nonatomic, readonly, getter=isValid) BOOL valid;
@property(nonatomic, readonly) NSError *error;

// currently, this is not always available
@property(nonatomic, readonly) LRVersionSpace *versionSpace;

@end
