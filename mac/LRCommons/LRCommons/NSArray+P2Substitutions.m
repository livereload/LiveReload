
#import "NSArray+P2Substitutions.h"


@implementation NSArray (P2Substitutions)

- (NSArray *)p2_arrayBySubstitutingValuesFromDictionary:(NSDictionary *)info {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    for (NSString *string in self) {
        __block NSString *mutable = [string copy];
        [info enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            if ([value isKindOfClass:[NSArray class]]) {
                if ([string isEqualToString:key]) {
                    [result addObjectsFromArray:value];
                    mutable = nil;
                    *stop = YES;
                }
            } else {
                mutable = [[mutable stringByReplacingOccurrencesOfString:key withString:value] copy];
            }
        }];
        // mutable is nil here iff we have replaced this item with an array
        if (mutable != nil) {
            [result addObject:mutable];
        }
    }
    return [NSArray arrayWithArray:result];
}

@end


@implementation NSString (P2Substitutions)

- (NSString *)p2_stringBySubstitutingValuesFromDictionary:(NSDictionary *)info {
    __block NSString *mutable = [self copy];
    [info enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        if ([value isKindOfClass:[NSArray class]]) {
        } else {
            mutable = [[mutable stringByReplacingOccurrencesOfString:key withString:value] copy];
        }
    }];
    return [NSString stringWithString:mutable];
}

@end
