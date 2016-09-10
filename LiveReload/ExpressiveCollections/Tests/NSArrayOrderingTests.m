@import XCTest;
@import ExpressiveCollections;

@interface NSArrayOrderingTests : XCTestCase

@end

@implementation NSArrayOrderingTests

- (void)test_minimalElement {
    NSArray *array = @[@11, @42, @26, @14, @30];
    id result = [array at_minimalElement];
    XCTAssertEqualObjects(result, @11);
}

- (void)test_maximalElement {
    NSArray *array = @[@11, @42, @26, @14, @30];
    id result = [array at_maximalElement];
    XCTAssertEqualObjects(result, @42);
}

- (void)test_minimalElementOrderedByIntegerScoringBlock {
    NSArray *array = @[@11, @42, @26, @14, @30];
    id result = [array at_minimalElementOrderedByIntegerScoringBlock:^NSInteger(NSNumber *value, NSUInteger idx) {
        return [value integerValue] % 10;
    }];
    XCTAssertEqualObjects(result, @30);
}

- (void)test_maximalElementOrderedByIntegerScoringBlock {
    NSArray *array = @[@11, @42, @26, @14, @30];
    id result = [array at_maximalElementOrderedByIntegerScoringBlock:^NSInteger(NSNumber *value, NSUInteger idx) {
        return [value integerValue] % 10;
    }];
    XCTAssertEqualObjects(result, @26);
}

- (void)test_minimalElementOrderedByDoubleScoringBlock {
    NSArray *array = @[@11, @42, @26, @14, @30];
    id result = [array at_minimalElementOrderedByDoubleScoringBlock:^double(id value, NSUInteger idx) {
        NSInteger v = [value integerValue];
        NSInteger firstDigit = v / 10;
        return (v % 2) + (double)firstDigit / 10;
    }];
    XCTAssertEqualObjects(result, @14);
}

- (void)test_maximalElementOrderedByDoubleScoringBlock {
    NSArray *array = @[@11, @42, @26, @14, @30];
    id result = [array at_maximalElementOrderedByDoubleScoringBlock:^double(id value, NSUInteger idx) {
        NSInteger v = [value integerValue];
        NSInteger firstDigit = v / 10;
        return (v % 2) + (double)firstDigit / 10;
    }];
    XCTAssertEqualObjects(result, @11);
}

@end
