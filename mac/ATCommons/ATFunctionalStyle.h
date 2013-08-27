
#import <Foundation/Foundation.h>


#pragma mark - ATKeyValueObservingWithBlocks

@interface ATObserver : NSObject {
@private
    id _object;
    void(^_handler)();
}

- (void)invalidate;

@end

@interface NSObject (ATKeyValueObservingWithBlocks)

- (ATObserver *)addObserverForKeyPath:(NSString *)keyPath owner:(id)owner block:(void(^)())block;

- (ATObserver *)addObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options owner:(id)owner block:(void(^)())block;

@end


#pragma mark - ATFunctionalStyleAdditions

@interface NSArray (ATFunctionalStyleAdditions)

- (NSDictionary *)dictionaryWithElementsGroupedByKeyPath:(NSString *)keyPath;
- (NSDictionary *)dictionaryWithElementsGroupedByBlock:(id(^)(id value))block;

- (NSDictionary *)dictionaryWithElementsGroupedIntoArraysByKeyPath:(NSString *)keyPath;

- (NSDictionary *)dictionaryWithElementsMultiGroupedByKeyPath:(NSString *)keyPath;
- (NSDictionary *)dictionaryWithElementsMultiGroupedByBlock:(NSArray *(^)(id value))block;

- (NSSet *)setWithElementsGroupedByKeyPath:(NSString *)keyPath;

- (NSArray *)arrayByMappingElementsToValueOfKeyPath:(NSString *)keyPath;

- (NSArray *)arrayByMappingElementsUsingBlock:(id(^)(id value))block;

- (NSArray *)filteredArrayUsingBlock:(BOOL(^)(id value))block;

- (NSArray *)arrayByMergingDictionaryValuesWithArray:(NSArray *)peer groupedByKeyPath:(NSString *)keyPath;

@end


@interface NSDictionary (ATFunctionalStyleAdditions)

- (NSDictionary *)dictionaryByReversingKeysAndValues;

- (NSDictionary *)dictionaryByMappingKeysToSelector:(SEL)selector;
- (NSDictionary *)dictionaryByMappingValuesToSelector:(SEL)selector;
- (NSDictionary *)dictionaryByMappingValuesToSelector:(SEL)selector withObject:(id)object;
- (NSDictionary *)dictionaryByMappingValuesToKeyPath:(NSString *)valueKeyPath;
- (NSDictionary *)dictionaryByMappingValuesToBlock:(id(^)(id key, id value))block;

- (NSDictionary *)dictionaryByMappingValuesAccordingToSchema:(NSDictionary *)schema;

- (NSDictionary *)dictionaryByAddingEntriesFromDictionary:(NSDictionary *)peer;

- (NSDictionary *)dictionaryByMergingDictionaryValuesWithDictionary:(NSDictionary *)peer;

@end
