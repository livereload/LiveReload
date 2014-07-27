#import <XCTest/XCTest.h>
@import ATPathSpec;


@interface ATPathSpecIntroTests : XCTestCase
@end

@implementation ATPathSpecIntroTests

- (void)testExample1 {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"docs/*.txt" syntaxOptions:ATPathSpecSyntaxFlavorGlob];
    XCTAssertTrue(![spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"more/docs/README.txt" type:ATPathSpecEntryTypeFile], "");
}

@end
