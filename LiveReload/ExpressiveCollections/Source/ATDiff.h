@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (ATDiff)

- (void)at_enumeratePairsMatchingObjectsInDictionary:(NSDictionary *)rhsObjects usingBlock:(void(^)(id _Nullable lhs, id _Nullable rhs))block;

@end

NS_ASSUME_NONNULL_END
