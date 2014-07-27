
#import <XCTest/XCTest.h>
#import "LRPathProcessing.h"
@import ATPathSpec;

@interface LRPathProcessingTests : XCTestCase
@end

@implementation LRPathProcessingTests

- (void)testTrivialCase {
    NSString *result = LRDeriveDestinationFileName(@"test.less", @"*.css", [ATPathSpec pathSpecWithString:@"*.less" syntaxOptions:ATPathSpecSyntaxFlavorExtended]);
    XCTAssertEqualObjects(result, @"test.css");
}

- (void)testMultipleSourceExtensions {
    NSString *result = LRDeriveDestinationFileName(@"test.scss", @"*.css", [ATPathSpec pathSpecWithString:@"*.sass *.scss" syntaxOptions:ATPathSpecSyntaxFlavorExtended]);
    XCTAssertEqualObjects(result, @"test.css");
}

- (void)testDoubleExtension {
    NSString *result = LRDeriveDestinationFileName(@"test.coffee.md", @"*.js", [ATPathSpec pathSpecWithString:@"*.coffee *.coffee.md" syntaxOptions:ATPathSpecSyntaxFlavorExtended]);
    XCTAssertEqualObjects(result, @"test.js");
}

@end
