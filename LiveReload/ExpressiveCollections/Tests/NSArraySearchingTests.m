@import XCTest;
@import ExpressiveCollections;

@interface NSArraySearchingTests : XCTestCase

@end

@implementation NSArraySearchingTests

- (void)test_firstElementPassingTest {
    NSArray *array = @[@11, @42, @26, @14, @30];
    id result = [array at_firstElementPassingTest:^BOOL(id value, NSUInteger idx, BOOL *stop) {
        return [value integerValue] >= 20;
    }];
    XCTAssertEqualObjects(result, @42);
}

- (void)test_lastElementPassingTest {
    NSArray *array = @[@11, @42, @26, @14, @30];
    id result = [array at_lastElementPassingTest:^BOOL(id value, NSUInteger idx, BOOL *stop) {
        return [value integerValue] >= 20;
    }];
    XCTAssertEqualObjects(result, @30);
}

@end
