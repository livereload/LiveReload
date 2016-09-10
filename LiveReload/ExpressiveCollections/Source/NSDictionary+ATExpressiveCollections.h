@import Foundation;


@interface NSDictionary (ATExpressiveCollections)

// {A: P, B: Q, C: R}  =>  {P: A, Q: B, R: C}
- (NSDictionary *)at_dictionaryByReversingKeysAndValues;

- (NSDictionary *)at_dictionaryByAddingEntriesFromDictionary:(NSDictionary *)peer;

- (NSDictionary *)at_dictionaryByMergingEntriesFromDictionary:(NSDictionary *)peer usingBlock:(id(^)(id key, id oldValue, id newValue))mergeBlock;

- (NSDictionary *)at_dictionaryByRecursivelyMergingEntriesFromDictionary:(NSDictionary *)peer;

// {A: P, B: Q, C: R}  =>  [x, y, z]
- (NSArray *)at_arrayWithValuesOfBlock:(id(^)(id key, id value))block;

// {A: P, B: Q, C: R}  =>  {x: P, y: Q, z: R}
- (NSDictionary *)at_dictionaryByMappingKeysUsingBlock:(id(^)(id key, id value))block;

// {A: P, B: Q, C: R}  =>  {A: x, B: y, C: z}
- (NSDictionary *)at_dictionaryByMappingValuesUsingBlock:(id(^)(id key, id value))block;

@end
