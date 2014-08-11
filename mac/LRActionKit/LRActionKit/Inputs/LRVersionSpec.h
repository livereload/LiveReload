@import Foundation;
#import "LRVersionTag.h"


@class LRVersion;
@class LRVersionSpace;
@class LRVersionSet;


typedef NS_ENUM(NSInteger, LRVersionSpecType) {
    LRVersionSpecTypeUnknown,
    LRVersionSpecTypeSpecific,
    LRVersionSpecTypeMajorMinor,
    LRVersionSpecTypeStableMajor,
    LRVersionSpecTypeStableAny,
};


// specific: 1.2.3
// latest 1.2.x (stable or beta)
// latest stable 1.x
@interface LRVersionSpec : NSObject <NSCopying>

+ (instancetype)versionSpecWithString:(NSString *)string inVersionSpace:(LRVersionSpace *)versionSpace;

+ (instancetype)stableVersionSpecMatchingAnyVersionInVersionSpace:(LRVersionSpace *)versionSpace;
+ (instancetype)versionSpecMatchingVersion:(LRVersion *)version;
+ (instancetype)versionSpecMatchingMajorMinorFromVersion:(LRVersion *)version;
+ (instancetype)stableVersionSpecWithMajorFromVersion:(LRVersion *)version;

@property(nonatomic, readonly) NSString *stringValue;

@property(nonatomic, readonly) NSString *title;

@property(nonatomic, readonly, getter=isValid) BOOL valid;

@property(nonatomic, readonly) LRVersionSpecType type;

@property(nonatomic, readonly) LRVersionSet *matchingVersionSet;
@property(nonatomic, readonly) LRVersionTag matchingVersionTags;

- (BOOL)matchesVersion:(LRVersion *)version withTag:(LRVersionTag)tag;

@property(nonatomic, strong) NSString *changeLogSummary;  // a quick hack

@end
