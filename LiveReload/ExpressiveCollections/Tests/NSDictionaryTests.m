@import XCTest;
@import ExpressiveCollections;

@interface NSDictionaryTests : XCTestCase

@end

@implementation NSDictionaryTests

- (void)test_dictionaryByReversingKeysAndValues {
    NSDictionary *example  = @{@"foo": @42, @"bar": @11};
    NSDictionary *expected = @{@42: @"foo", @11: @"bar"};
    XCTAssertEqualObjects([example at_dictionaryByReversingKeysAndValues], expected);
}

- (void)test_dictionaryByAddingEntriesFromDictionary {
    NSDictionary *first = @{@"foo": @42, @"bar": @11};
    NSDictionary *second = @{@"bar": @12, @"boz": @100};
    NSDictionary *expected = @{@"foo": @42, @"bar": @12, @"boz": @100};
    XCTAssertEqualObjects([first at_dictionaryByAddingEntriesFromDictionary:second], expected);
}

@end
