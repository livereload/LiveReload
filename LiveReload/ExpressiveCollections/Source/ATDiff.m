#import "ATDiff.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSDictionary (ATDiff)

- (void)at_enumeratePairsMatchingObjectsInDictionary:(NSDictionary *)rhsObjects usingBlock:(void(^)(id _Nullable lhs, id _Nullable rhs))block {
    NSMutableDictionary *remainingRightObjects = [rhsObjects mutableCopy];

    [self enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull lhsObj, BOOL * _Nonnull stop) {
        id rhsObj = remainingRightObjects[key];
        block(lhsObj, rhsObj);
        if (rhsObj) {
            [remainingRightObjects removeObjectForKey:key];
        }
    }];

    [remainingRightObjects enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull rhsObj, BOOL * _Nonnull stop) {
        block(nil, rhsObj);
    }];
}

@end

NS_ASSUME_NONNULL_END
