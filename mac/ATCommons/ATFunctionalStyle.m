
#import "ATFunctionalStyle.h"
#import <objc/runtime.h>


#pragma mark - ATKeyValueObservingWithBlocks

@implementation ATObserver

- (id)initWithObject:(id)object handler:(void(^)())handler {
    self = [super init];
    if (self) {
        _object = object;
        _handler = [handler copy];
    }
    return self;
}

- (void)invalidate {
    [_object removeObserver:self];
    _object = nil;
    _handler = nil;
}

- (void)dealloc {
    [self invalidate];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    _handler();
}

@end

@interface ATObserverCollection : NSObject {
@private
    NSMutableArray *_observers;
}
@end

@implementation ATObserverCollection

- (id)init {
    self = [super init];
    if (self) {
        _observers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addObserver:(ATObserver *)observer {
    [_observers addObject:observer];
}

@end

@implementation NSObject (ATKeyValueObservingWithBlocks)

- (ATObserverCollection *)AT_observerCollection {
    ATObserverCollection *collection = objc_getAssociatedObject(self, _cmd);
    if (collection == nil) {
        collection = [[ATObserverCollection alloc] init];
        objc_setAssociatedObject(self, _cmd, collection, OBJC_ASSOCIATION_RETAIN);
    }
    return collection;
}

- (ATObserver *)addObserverForKeyPath:(NSString *)keyPath owner:(id)owner block:(void(^)())block {
    return [self addObserverForKeyPath:keyPath options:0 owner:owner block:block];
}

- (ATObserver *)addObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options owner:(id)owner block:(void(^)())block {
    ATObserver *observer = [[ATObserver alloc] initWithObject:self handler:block];
    [[owner AT_observerCollection] addObserver:observer];
    return observer;
}

@end


#pragma mark - ATFunctionalStyleAdditions

@implementation NSArray (ATFunctionalStyleAdditions)

- (NSDictionary *)dictionaryWithElementsGroupedByKeyPath:(NSString *)keyPath {
    NSMutableDictionary *grouped = [NSMutableDictionary dictionary];
    for (id element in self) {
        id key = [element valueForKeyPath:keyPath];
        if (key == nil)
            continue;
        [grouped setObject:element forKey:key];
    }
    return grouped;
}

- (NSDictionary *)dictionaryWithElementsGroupedIntoArraysByKeyPath:(NSString *)keyPath {
    NSMutableDictionary *grouped = [NSMutableDictionary dictionary];
    for (id element in self) {
        id key = [element valueForKeyPath:keyPath];
        if (key == nil)
            continue;

        NSMutableArray *array = grouped[key];
        if (!array) {
            array = [NSMutableArray new];
            grouped[key] = array;
        }
        [array addObject:element];
    }
    return grouped;
}

- (NSDictionary *)dictionaryWithElementsGroupedByBlock:(id(^)(id value))block {
    NSMutableDictionary *grouped = [NSMutableDictionary dictionary];
    for (id element in self) {
        id key = block(element);
        if (key == nil)
            continue;
        [grouped setObject:element forKey:key];
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

- (NSDictionary *)dictionaryWithElementsMultiGroupedByBlock:(NSArray *(^)(id value))block {
    NSMutableDictionary *grouped = [NSMutableDictionary dictionary];
    for (id element in self) {
        NSArray *keys = block(element);
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

- (NSArray *)filteredArrayUsingBlock:(BOOL(^)(id value))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    for (id element in self) {
        if (block(element))
            [result addObject:element];
    }
    return result;
}

- (NSArray *)arrayByMergingDictionaryValuesWithArray:(NSArray *)peer groupedByKeyPath:(NSString *)keyPath {
    NSDictionary *first = [self dictionaryWithElementsGroupedByKeyPath:keyPath];
    NSDictionary *second = [peer dictionaryWithElementsGroupedByKeyPath:keyPath];
    NSDictionary *merged = [first dictionaryByMergingDictionaryValuesWithDictionary:second];
    return [merged allValues];
}

@end


@implementation NSDictionary (ATFunctionalStyleAdditions)

- (NSDictionary *)dictionaryByReversingKeysAndValues {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        result[obj] = key;
    }];
    return result;
}

- (NSDictionary *)dictionaryByMappingKeysToSelector:(SEL)selector {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result setObject:obj forKey:[key performSelector:selector withObject:nil]];
    }];
    return result;
}

- (NSDictionary *)dictionaryByMappingValuesToSelector:(SEL)selector {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result setObject:[obj performSelector:selector withObject:nil] forKey:key];
    }];
    return result;
}

- (NSDictionary *)dictionaryByMappingValuesToSelector:(SEL)selector withObject:(id)object {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result setObject:[obj performSelector:selector withObject:object] forKey:key];
    }];
    return result;
}

- (NSDictionary *)dictionaryByMappingValuesToKeyPath:(NSString *)valueKeyPath {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result setObject:[obj valueForKeyPath:valueKeyPath] forKey:key];
    }];
    return result;
}

- (NSDictionary *)dictionaryByMappingValuesToBlock:(id(^)(id key, id value))block {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id newValue = block(key, obj);
        if (newValue)
            result[key] = newValue;
    }];
    return result;
}

- (NSDictionary *)dictionaryByMappingValuesAccordingToSchema:(NSDictionary *)schema {
    schema = [schema dictionaryByReversingKeysAndValues];

    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        id outputKey = schema[key];
        if (outputKey)
            result[outputKey] = value;
    }];
    return result;
}

- (NSDictionary *)dictionaryByAddingEntriesFromDictionary:(NSDictionary *)peer {
    NSMutableDictionary *result = [self mutableCopy];
    [result addEntriesFromDictionary:peer];
    return result;
}

- (NSDictionary *)dictionaryByMergingDictionaryValuesWithDictionary:(NSDictionary *)peer {
    NSMutableDictionary *result = [self mutableCopy];
    [peer enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        id oldValue = result[key];
        if ([oldValue isKindOfClass:[NSDictionary class]] && [value isKindOfClass:[NSDictionary class]]) {
            value = [oldValue dictionaryByMergingDictionaryValuesWithDictionary:value];
        }
        result[key] = value;
    }];
    return result;
}

- (NSArray *)arrayByMappingEntriesUsingBlock:(id(^)(id key, id value))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        id item = block(key, value);
        if (item == nil)
            return;
        [result addObject:item];
    }];
    return result;
}

@end
