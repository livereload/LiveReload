#import "NSArray+ATExpressiveCollections.h"

@implementation NSArray (ATExpressiveCollections_MappingMethods)

- (NSArray *)at_arrayWithValuesOfBlock:(id(^)(id value, NSUInteger idx))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        id value = block(element, idx);
        if (value != nil) {
            [result addObject:value];
        }
    }];
    return result;
}

- (NSArray *)at_arrayWithValuesOfKeyPath:(NSString *)keyPath {
    return [self at_arrayWithValuesOfBlock:^id(id element, NSUInteger idx) {
        return [element valueForKeyPath:keyPath];
    }];
}

@end


@implementation NSArray (ATExpressiveCollections_FilteringMethods)

- (NSArray *)at_arrayOfElementsPassingTest:(BOOL(^)(id value, NSUInteger idx))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        if (block(element, idx)) {
            [result addObject:element];
        }
    }];
    return result;
}

@end


@implementation NSArray (ATExpressiveCollections_SearchingMethods)

- (id)at_firstElementPassingTest:(BOOL(^)(id value, NSUInteger idx, BOOL *stop))block {
    NSUInteger idx = [self indexOfObjectWithOptions:0 passingTest:block];
    if (idx == NSNotFound) {
        return nil;
    } else {
        return self[idx];
    }
}

- (id)at_lastElementPassingTest:(BOOL(^)(id value, NSUInteger idx, BOOL *stop))block {
    NSUInteger idx = [self indexOfObjectWithOptions:NSEnumerationReverse passingTest:block];
    if (idx == NSNotFound) {
        return nil;
    } else {
        return self[idx];
    }
}

@end


@implementation NSArray (ATExpressiveCollections_OrderingMethods)

- (id)at_minimalElementOrderedByIntegerScoringBlock:(NSInteger(^)(id value, NSUInteger idx))block {
    __block id bestElement = nil;
    __block NSInteger bestScore = NSIntegerMax;

    [self enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        NSInteger score = block(element, idx);
        if (bestElement == nil || score < bestScore) {
            bestElement = element;
            bestScore = score;
        }
    }];
    return bestElement;
}

- (id)at_minimalElementOrderedByDoubleScoringBlock:(double(^)(id value, NSUInteger idx))block {
    __block id bestElement = nil;
    __block double bestScore = DBL_MAX;

    [self enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        double score = block(element, idx);
        if (bestElement == nil || score < bestScore) {
            bestElement = element;
            bestScore = score;
        }
    }];
    return bestElement;
}

- (id)at_minimalElementOrderedByObjectScoringBlock:(id(^)(id value, NSUInteger idx))block {
    __block id bestElement = nil;
    __block id bestScore = nil;

    [self enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        id score = block(element, idx);
        if (bestElement == nil || [score compare:bestScore] == NSOrderedAscending) {
            bestElement = element;
            bestScore = score;
        }
    }];
    return bestElement;
}

- (id)at_minimalElement {
    return [self at_minimalElementOrderedByObjectScoringBlock:^id(id value, NSUInteger idx) {
        return value;
    }];
}

- (id)at_maximalElementOrderedByIntegerScoringBlock:(NSInteger(^)(id value, NSUInteger idx))block {
    __block id bestElement = nil;
    __block NSInteger bestScore = NSIntegerMax;

    [self enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        NSInteger score = block(element, idx);
        if (bestElement == nil || score > bestScore) {
            bestElement = element;
            bestScore = score;
        }
    }];
    return bestElement;
}

- (id)at_maximalElementOrderedByDoubleScoringBlock:(double(^)(id value, NSUInteger idx))block {
    __block id bestElement = nil;
    __block double bestScore = DBL_MIN;

    [self enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        double score = block(element, idx);
        if (bestElement == nil || score > bestScore) {
            bestElement = element;
            bestScore = score;
        }
    }];
    return bestElement;
}

- (id)at_maximalElementOrderedByObjectScoringBlock:(id(^)(id value, NSUInteger idx))block {
    __block id bestElement = nil;
    __block id bestScore = nil;

    [self enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        id score = block(element, idx);
        if (bestElement == nil || [score compare:bestScore] == NSOrderedDescending) {
            bestElement = element;
            bestScore = score;
        }
    }];
    return bestElement;
}

- (id)at_maximalElement {
    return [self at_maximalElementOrderedByObjectScoringBlock:^id(id value, NSUInteger idx) {
        return value;
    }];
}

@end


@implementation NSArray (ATExpressiveCollections_GroupingMethods)

- (NSDictionary *)at_keyedElementsIndexedByValueOfBlock:(id(^)(id value, NSUInteger idx))block {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        id key = block(element, idx);
        if (key != nil) {
            result[key] = element;
        }
    }];
    return result;
}

- (NSDictionary *)at_keyedElementsIndexedByValueOfKeyPath:(NSString *)keyPath {
    return [self at_keyedElementsIndexedByValueOfBlock:^id(id value, NSUInteger idx) {
        return [value valueForKeyPath:keyPath];
    }];
}

- (NSDictionary *)at_dictionaryMappingElementsToValuesOfBlock:(id(^)(id value, NSUInteger idx))valueBlock {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        id value = valueBlock(element, idx);
        if (value != nil) {
            result[element] = value;
        }
    }];
    return result;
}

@end


@implementation NSArray (ATExpressiveCollections_MultiInstanceGroupingMethods)

- (NSDictionary *)at_keyedArraysOfElementsGroupedByValueOfBlock:(id(^)(id element, NSUInteger idx))block {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        id key = block(element, idx);
        if (key != nil) {
            NSMutableArray *instances = result[key];
            if (instances == nil) {
                instances = [NSMutableArray new];
                result[key] = instances;
            }
            [instances addObject:element];
        }
    }];
    return result;
}

- (NSDictionary *)at_keyedArraysOfElementsGroupedByValueOfKeyPath:(NSString *)keyPath {
    return [self at_keyedArraysOfElementsGroupedByValueOfBlock:^id(id element, NSUInteger idx) {
        return [element valueForKeyPath:keyPath];
    }];
}

@end
