
#import <Foundation/Foundation.h>


@class LRVersion;
@class LRVersionSpace;


@interface LRVersionRange : NSObject

+ (instancetype)versionRangeWithVersion:(LRVersion *)version;
+ (instancetype)unboundedVersionRange;

- (instancetype)initWithStartingVersion:(LRVersion *)startingVersion startIncluded:(BOOL)startIncluded endingVersion:(LRVersion *)endingVersion endIncluded:(BOOL)endIncluded;

@property(nonatomic, readonly) LRVersion *startingVersion;
@property(nonatomic, readonly) LRVersion *endingVersion;

@property(nonatomic, readonly, getter=isStartIncluded) BOOL startIncluded;
@property(nonatomic, readonly, getter=isEndIncluded) BOOL endIncluded;

- (BOOL)containsVersion:(LRVersion *)version;

@property(nonatomic, readonly, getter=isValid) BOOL valid;
@property(nonatomic, readonly) NSError *error;

// currently, this is not always available
@property(nonatomic, readonly) LRVersionSpace *versionSpace;

@end
