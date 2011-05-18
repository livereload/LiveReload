
#import "ATFunctionalStyle.h"


@implementation NSArray (ATFunctionalStyleAdditions)

- (NSDictionary *)dictionaryWithElementsGroupedByKeyPath:(NSString *)keyPath {
    NSMutableDictionary *grouped = [NSMutableDictionary dictionary];
    for (id element in self) {
        id key = [element valueForKeyPath:keyPath];
        NSMutableArray *array = [grouped objectForKey:key];
        if (!array) {
            array = [NSMutableArray array];
            [grouped setObject:array forKey:key];
        }
        [array addObject:element];
    }
    return grouped;
}

- (NSDictionary *)dictionaryWithElementsMultiGroupedByKeyPath:(NSString *)keyPath {
    NSMutableDictionary *grouped = [NSMutableDictionary dictionary];
    for (id element in self) {
        NSArray *keys = [element valueForKeyPath:keyPath];
        for (id key in keys) {
            NSMutableArray *array = [grouped objectForKey:key];
            if (!array) {
                array = [NSMutableArray array];
                [grouped setObject:array forKey:key];
            }
            [array addObject:element];
        }
    }
    return grouped;
}

- (NSSet *)setWithElementsGroupedByKeyPath:(NSString *)keyPath {
    NSMutableSet *result = [NSMutableSet set];
    for (id element in self) {
        id key = [element valueForKeyPath:keyPath];
        if (key == nil)
            continue;
        [result addObject:key];
    }
    return result;
}

- (NSArray *)arrayByMappingElementsToValueOfKeyPath:(NSString *)keyPath {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    for (id element in self) {
        id value = [element valueForKeyPath:keyPath];
        if (value == nil)
            continue;
        [result addObject:value];
    }
    return result;
}

- (NSArray *)arrayByMappingElementsUsingBlock:(id(^)(id value))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    for (id element in self) {
        id value = block(element);
        if (value == nil)
            continue;
        [result addObject:value];
    }
    return result;
}

@end
