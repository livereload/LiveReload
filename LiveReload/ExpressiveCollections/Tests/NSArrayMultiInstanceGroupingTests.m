@import XCTest;
@import ExpressiveCollections;

@interface NSArrayMultiInstanceGroupingTests : XCTestCase

@end

@implementation NSArrayMultiInstanceGroupingTests

- (void)test_keyedElementsByValueOfBlock {
    NSArray *array = @[@"foo", @"bar", @"Foo", @"Bar", @"boz"];
    NSDictionary *result = [array at_keyedArraysOfElementsGroupedByValueOfBlock:^id(NSString *value, NSUInteger idx) {
        return [value uppercaseString];
    }];
    NSDictionary *expected = @{@"FOO": @[@"foo", @"Foo"], @"BAR": @[@"bar", @"Bar"], @"BOZ": @[@"boz"]};
    XCTAssertEqualObjects(result, expected);
}

@end
