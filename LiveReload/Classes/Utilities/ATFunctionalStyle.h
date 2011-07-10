
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

- (NSDictionary *)dictionaryWithElementsMultiGroupedByKeyPath:(NSString *)keyPath;

- (NSSet *)setWithElementsGroupedByKeyPath:(NSString *)keyPath;

- (NSArray *)arrayByMappingElementsToValueOfKeyPath:(NSString *)keyPath;

- (NSArray *)arrayByMappingElementsUsingBlock:(id(^)(id value))block;

@end


@interface NSDictionary (ATFunctionalStyleAdditions)

- (NSDictionary *)dictionaryByMappingKeysToSelector:(SEL)selector;
- (NSDictionary *)dictionaryByMappingValuesToSelector:(SEL)selector;
- (NSDictionary *)dictionaryByMappingValuesToSelector:(SEL)selector withObject:(id)object;
- (NSDictionary *)dictionaryByMappingValuesToKeyPath:(NSString *)valueKeyPath;

@end
