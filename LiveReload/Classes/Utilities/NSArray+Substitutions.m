
#import "NSArray+Substitutions.h"


@implementation NSArray (Substitutions)

- (NSArray *)arrayBySubstitutingValuesFromDictionary:(NSDictionary *)info {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    for (NSString *string in self) {
        __block NSString *mutable = [string copy];
        [info enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            NSString *old = mutable;
            mutable = [[mutable stringByReplacingOccurrencesOfString:key withString:value] copy];
            [old release];
        }];
        [result addObject:mutable];
        [mutable release];
    }
    return [NSArray arrayWithArray:result];
}

@end
