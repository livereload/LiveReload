
#import <Foundation/Foundation.h>


@class LRVersion;
@class LRVersionSpace;


NS_ASSUME_NONNULL_BEGIN

@interface LRVersionRange : NSObject

+ (instancetype)versionRangeWithVersion:(LRVersion *)version;
+ (instancetype)unboundedVersionRange;

- (instancetype)initWithStartingVersion:(nullable LRVersion *)startingVersion startIncluded:(BOOL)startIncluded endingVersion:(nullable LRVersion *)endingVersion endIncluded:(BOOL)endIncluded;

@property(nonatomic, readonly, nullable) LRVersion *startingVersion;
@property(nonatomic, readonly, nullable) LRVersion *endingVersion;

@property(nonatomic, readonly, getter=isStartIncluded) BOOL startIncluded;
@property(nonatomic, readonly, getter=isEndIncluded) BOOL endIncluded;

- (BOOL)containsVersion:(LRVersion *)version;

@property(nonatomic, readonly, getter=isValid) BOOL valid;
@property(nonatomic, readonly, nullable) NSError *error;

// currently, this is not always available
@property(nonatomic, readonly, nullable) LRVersionSpace *versionSpace;

@end

NS_ASSUME_NONNULL_END
