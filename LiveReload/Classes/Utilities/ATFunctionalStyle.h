
#import <Foundation/Foundation.h>


@interface NSArray (ATFunctionalStyleAdditions)

- (NSDictionary *)dictionaryWithElementsGroupedByKeyPath:(NSString *)keyPath;

- (NSDictionary *)dictionaryWithElementsMultiGroupedByKeyPath:(NSString *)keyPath;

- (NSSet *)setWithElementsGroupedByKeyPath:(NSString *)keyPath;

- (NSArray *)arrayByMappingElementsToValueOfKeyPath:(NSString *)keyPath;

- (NSArray *)arrayByMappingElementsUsingBlock:(id(^)(id value))block;

@end
