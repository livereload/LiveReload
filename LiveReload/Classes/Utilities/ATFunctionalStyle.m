
#import "ATFunctionalStyle.h"
#import <objc/runtime.h>


#pragma mark - ATKeyValueObservingWithBlocks

@implementation ATObserver

- (id)initWithObject:(id)object handler:(void(^)())handler {
    self = [super init];
    if (self) {
        _object = [object retain];
        _handler = [handler copy];
    }
    return self;
}

- (void)invalidate {
    [_object removeObserver:self];
    [_object release], _object = nil;
    [_handler release], _handler = nil;
}

- (void)dealloc {
    [self invalidate];
    [super dealloc];
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

- (void)dealloc {
    [_observers release], _observers = nil;
    [super dealloc];
}

@end

@implementation NSObject (ATKeyValueObservingWithBlocks)

- (ATObserverCollection *)AT_observerCollection {
    ATObserverCollection *collection = objc_getAssociatedObject(self, _cmd);
    if (collection == nil) {
        collection = [[[ATObserverCollection alloc] init] autorelease];
        objc_setAssociatedObject(self, _cmd, collection, OBJC_ASSOCIATION_RETAIN);
    }
    return collection;
}

- (ATObserver *)addObserverForKeyPath:(NSString *)keyPath owner:(id)owner block:(void(^)())block {
    return [self addObserverForKeyPath:keyPath options:0 owner:owner block:block];
}

- (ATObserver *)addObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options owner:(id)owner block:(void(^)())block {
    ATObserver *observer = [[[ATObserver alloc] initWithObject:self handler:block] autorelease];
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

- (NSArray *)filteredArrayUsingBlock:(BOOL(^)(id value))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    for (id element in self) {
        if (block(element))
            [result addObject:element];
    }
    return result;
}

@end


@implementation NSDictionary (ATFunctionalStyleAdditions)

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

@end
