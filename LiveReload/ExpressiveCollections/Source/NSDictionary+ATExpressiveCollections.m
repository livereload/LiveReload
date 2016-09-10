#import "NSDictionary+ATExpressiveCollections.h"

@implementation NSDictionary (ATExpressiveCollections)

- (NSDictionary *)at_dictionaryByReversingKeysAndValues {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        result[obj] = key;
    }];
    return result;
}

- (NSDictionary *)at_dictionaryByAddingEntriesFromDictionary:(NSDictionary *)peer {
    NSMutableDictionary *result = [self mutableCopy];
    [result addEntriesFromDictionary:peer];
    return result;
}

- (NSDictionary *)at_dictionaryByMergingEntriesFromDictionary:(NSDictionary *)peer usingBlock:(id(^)(id key, id oldValue, id newValue))mergeBlock {
    NSMutableDictionary *result = [self mutableCopy];
    [peer enumerateKeysAndObjectsUsingBlock:^(id key, id newValue, BOOL *stop) {
        id oldValue = result[key];
        if (oldValue == nil) {
            result[key] = newValue;
        } else {
            result[key] = mergeBlock(key, oldValue, newValue);
        }
    }];
    return result;
}

- (NSDictionary *)at_dictionaryByRecursivelyMergingEntriesFromDictionary:(NSDictionary *)peer {
    return [self at_dictionaryByMergingEntriesFromDictionary:peer usingBlock:^id(id key, id oldValue, id newValue) {
        if ([oldValue isKindOfClass:[NSDictionary class]] && [newValue isKindOfClass:[NSDictionary class]]) {
            return [oldValue at_dictionaryByRecursivelyMergingEntriesFromDictionary:newValue];
        } else {
            return newValue;
        }
    }];
}

- (NSArray *)at_arrayWithValuesOfBlock:(id(^)(id key, id value))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        id item = block(key, value);
        if (item != nil) {
            [result addObject:item];
        }
    }];
    return result;
}

- (NSDictionary *)at_dictionaryByMappingKeysUsingBlock:(id(^)(id key, id value))block {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        id newKey = block(key, value);
        if (newKey) {
            result[newKey] = value;
        }
    }];
    return result;
}

- (NSDictionary *)at_dictionaryByMappingValuesUsingBlock:(id(^)(id key, id value))block {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        id newValue = block(key, value);
        if (newValue) {
            result[key] = newValue;
        }
    }];
    return result;
}

@end
