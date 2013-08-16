
#import <XCTest/XCTest.h>
#import "ATPathSpecPrivate.h"


@interface ATPathSpecTokenizerTests : XCTestCase
@end

@implementation ATPathSpecTokenizerTests

- (void)testSingleMask {
    NSString *actual = [ATPathSpec describeTokensInString:@"*.txt" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"Mask(*.txt)", "");
}

- (void)testComma {
    NSString *actual = [ATPathSpec describeTokensInString:@"*.txt, *.html" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"Mask(*.txt) , Mask(*.html)", "");
}

- (void)testWhitespace {
    NSString *actual = [ATPathSpec describeTokensInString:@"*.txt *.html" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"Mask(*.txt) _ Mask(*.html)", "");
}

- (void)testEscapedWhitespace {
    NSString *actual = [ATPathSpec describeTokensInString:@"*.txt\\ *.html" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"Mask(*.txt *.html)", "");
}

- (void)testNewline {
    NSString *actual = [ATPathSpec describeTokensInString:@"*.txt\n*.html" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"Mask(*.txt) ; Mask(*.html)", "");
}

- (void)testLeadingComment {
    NSString *actual = [ATPathSpec describeTokensInString:@"# hey\n*.txt\n*.html" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"Mask(*.txt) ; Mask(*.html)", "");
}
- (void)testTrailingCommentWithoutNewline {
    NSString *actual = [ATPathSpec describeTokensInString:@"*.txt\n*.html\n# sayonara" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"Mask(*.txt) ; Mask(*.html)", "");
}
- (void)testTrailingCommentWithNewline {
    NSString *actual = [ATPathSpec describeTokensInString:@"*.txt\n*.html\n# sayonara\n" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"Mask(*.txt) ; Mask(*.html)", "");
}
- (void)testMidLineComment {
    NSString *actual = [ATPathSpec describeTokensInString:@"*.txt #, *.doc\n*.html" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"Mask(*.txt) ; Mask(*.html)", "");
}
- (void)testEscapedMidlineComment {
    NSString *actual = [ATPathSpec describeTokensInString:@"*.txt\\#, *.doc\n*.html" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"Mask(*.txt#) , Mask(*.doc) ; Mask(*.html)", "");
}

- (void)testNegationOfSingleMask {
    NSString *actual = [ATPathSpec describeTokensInString:@"!*.txt" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"! Mask(*.txt)", "");
}

- (void)testDoubleNegationOfSingleMask {
    NSString *actual = [ATPathSpec describeTokensInString:@" ! ! *.txt" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"! ! Mask(*.txt)", "");
}

- (void)testNegationOfParen {
    NSString *actual = [ATPathSpec describeTokensInString:@" ! (*.txt, *.html)" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"! ( Mask(*.txt) , Mask(*.html) )", "");
}

- (void)testCommaInPlainPattern {
    NSString *actual = [ATPathSpec describeTokensInString:@"*.txt, *.html" withSyntaxOptions:ATPathSpecSyntaxFlavorGlob];
    XCTAssertEqualObjects(actual, @"Mask(*.txt, *.html)", "");
}

- (void)testWhitespaceSeparatedParens {
    NSString *actual = [ATPathSpec describeTokensInString:@"(a.txt a.html) (b.txt b.html)" withSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects(actual, @"( Mask(a.txt) _ Mask(a.html) ) _ ( Mask(b.txt) _ Mask(b.html) )", "");
}

@end
