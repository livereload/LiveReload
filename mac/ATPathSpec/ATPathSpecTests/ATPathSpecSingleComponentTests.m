
#import <XCTest/XCTest.h>
#import "ATPathSpec.h"


@interface ATPathSpecSingleComponentTests : XCTestCase
@end

@implementation ATPathSpecSingleComponentTests

- (void)testEmpty1 {
    ATPathSpec *spec = [ATPathSpec emptyPathSpec];
    XCTAssertEqualObjects([spec description], @"()", "");
    XCTAssertTrue(![spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
}
- (void)testEmpty2 {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"()", "");
    XCTAssertTrue(![spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
}
- (void)testEmpty3 {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"()" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"()", "");
    XCTAssertTrue(![spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
}

- (void)testLiteralName {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"README.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"README.txt", "");
    XCTAssertTrue( [spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"readme.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"README.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile], "");
}

- (void)testSingleMask {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"*.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"*.txt", "");
    XCTAssertTrue( [spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"README.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"docs/README.html" type:ATPathSpecEntryTypeFile], "");
}

- (void)testSingleNegatedMask {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"!*.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"!*.txt", "");
    XCTAssertTrue(![spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"README.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/README.html" type:ATPathSpecEntryTypeFile], "");
}

- (void)testPipeUnion {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"*.txt | *.html" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertTrue( [spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"README.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"README.doc" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/README.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"docs/README.doc" type:ATPathSpecEntryTypeFile], "");
}

- (void)testNegatedUnion {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"!(*.txt | *.html)" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertTrue(![spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"README.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"README.doc" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"docs/README.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/README.doc" type:ATPathSpecEntryTypeFile], "");
}

- (void)testCommaUnion {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"*.txt, *.html" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"*.txt | *.html", "");
}

- (void)testWhitespaceUnion {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"*.txt *.html" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"*.txt | *.html", "");
}

- (void)testNegatedWhitespaceUnion {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"!(*.txt *.html)" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"!(*.txt | *.html)", "");
}

- (void)testCommaListWithNegations {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"*.txt *.html !README.* README.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"((*.txt | *.html) & !README.*) | README.txt", "");
    XCTAssertTrue( [spec matchesPath:@"hellow.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"hellow.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"README.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"README.doc" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/hellow.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/hellow.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"docs/README.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"docs/README.doc" type:ATPathSpecEntryTypeFile], "");
}

- (void)testIntersection {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"*.txt & README.*" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertTrue( [spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"README.doc" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"hellow.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"docs/README.doc" type:ATPathSpecEntryTypeFile], "");
}

@end
