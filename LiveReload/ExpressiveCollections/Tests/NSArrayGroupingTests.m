@import XCTest;
@import ExpressiveCollections;

@interface NSArrayGroupingTests : XCTestCase

@end

@implementation NSArrayGroupingTests

- (void)test_keyedElementsByValueOfBlock {
    NSArray *array = @[@"foo", @"bar", @"boz"];
    NSDictionary *result = [array at_keyedElementsIndexedByValueOfBlock:^id(NSString *value, NSUInteger idx) {
        return [value uppercaseString];
    }];
    NSDictionary *expected = @{@"FOO": @"foo", @"BAR": @"bar", @"BOZ": @"boz"};
    XCTAssertEqualObjects(result, expected);
}

- (void)test_dictionaryMappingElementsToValuesOfBlock {
    NSArray *array = @[@"foo", @"bar", @"boz"];
    NSDictionary *result = [array at_dictionaryMappingElementsToValuesOfBlock:^id(NSString *value, NSUInteger idx) {
        return [value uppercaseString];
    }];
    NSDictionary *expected = @{@"foo": @"FOO", @"bar": @"BAR", @"boz": @"BOZ"};
    XCTAssertEqualObjects(result, expected);
}

@end
