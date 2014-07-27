#import <XCTest/XCTest.h>
@import ATPathSpec;


@interface ATPathSpecMetadataTests : XCTestCase
@end

@implementation ATPathSpecMetadataTests

- (void)testStrictFileName {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"README.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertTrue( [spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFolder], "");
}

- (void)testGitStyleFileName {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"README.txt" syntaxOptions:ATPathSpecSyntaxFlavorGitignore];
    XCTAssertTrue( [spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFolder], "");
}

- (void)testStrictFolderName {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"README.txt/" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertTrue(![spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFolder], "");
}

- (void)testGitStyleFolderName {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"README.txt/" syntaxOptions:ATPathSpecSyntaxFlavorGitignore];
    XCTAssertTrue(![spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFolder], "");
}

@end
