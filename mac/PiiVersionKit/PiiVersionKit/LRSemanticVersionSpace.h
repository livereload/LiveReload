
#import "LRVersionSpace.h"


@class LRSemanticVersion;


@interface LRSemanticVersionSpace : LRVersionSpace

+ (instancetype)semanticVersionSpace;

- (LRSemanticVersion *)versionWithString:(NSString *)string;

@end
