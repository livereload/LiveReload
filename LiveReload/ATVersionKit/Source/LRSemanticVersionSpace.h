
#import "LRVersionSpace.h"


@class LRSemanticVersion;

NS_ASSUME_NONNULL_BEGIN

@interface LRSemanticVersionSpace : LRVersionSpace

+ (instancetype)semanticVersionSpace;

- (LRSemanticVersion *)versionWithString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
