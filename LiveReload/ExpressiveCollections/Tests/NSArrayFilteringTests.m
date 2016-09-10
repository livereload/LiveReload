@import XCTest;
@import ExpressiveCollections;

@interface NSArrayFilteringTests : XCTestCase

@end

@implementation NSArrayFilteringTests

- (void)test_arrayWithValuesOfBlock {
    NSArray *array = @[@"foo", @"bar", @"boz"];
    NSArray *result = [array at_arrayWithValuesOfBlock:^id(id value, NSUInteger idx) {
        return [value uppercaseString];
    }];
    NSArray *expected = @[@"FOO", @"BAR", @"BOZ"];
    XCTAssertEqualObjects(result, expected);
}

- (void)test_arrayWithValuesOfBlock_nil {
    NSArray *array = @[@"foo", @"bar", @"boz"];
    NSArray *result = [array at_arrayWithValuesOfBlock:^id(id value, NSUInteger idx) {
        if ([value rangeOfString:@"o"].location != NSNotFound) {
            return [value uppercaseString];
        } else {
            return nil;
        }
    }];
    NSArray *expected = @[@"FOO", @"BOZ"];
    XCTAssertEqualObjects(result, expected);
}

- (void)test_arrayWithValuesOfKeyPath {
    NSArray *array = @[@"foo", @"bar", @"boz"];
    NSArray *result = [array at_arrayWithValuesOfKeyPath:@"uppercaseString"];
    NSArray *expected = @[@"FOO", @"BAR", @"BOZ"];
    XCTAssertEqualObjects(result, expected);
}

@end
