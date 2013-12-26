//
//  ATPathSpecMatchInfoTests.m
//  ATPathSpecExample
//
//  Created by Andrey Tarantsov on 26.12.2013.
//  Copyright (c) 2013 Andrey Tarantsov. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ATPathSpec.h"

@interface ATPathSpecMatchInfoTests : XCTestCase
@end

@implementation ATPathSpecMatchInfoTests

- (void)testStaticNameMatch {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"README.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    NSDictionary *info = [spec matchInfoForPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile];
    XCTAssertNotNil(info);
    XCTAssertEqualObjects(info[ATPathSpecMatchInfoMatchedStaticName], @"README.txt");
    XCTAssertNil(info[ATPathSpecMatchInfoMatchedSuffix]);
}

- (void)testStaticNameInSubdirMatch {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"docs/README.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    NSDictionary *info = [spec matchInfoForPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile];
    XCTAssertNotNil(info);
    XCTAssertEqualObjects(info[ATPathSpecMatchInfoMatchedStaticName], @"README.txt");
    XCTAssertNil(info[ATPathSpecMatchInfoMatchedSuffix]);
}

- (void)testSuffixMaskMatch {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"*.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    NSDictionary *info = [spec matchInfoForPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile];
    XCTAssertNotNil(info);
    XCTAssertNil(info[ATPathSpecMatchInfoMatchedStaticName]);
    XCTAssertEqualObjects(info[ATPathSpecMatchInfoMatchedSuffix], @".txt");
}

- (void)testDoubleExtensionSuffixMaskMatch {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"*.coffee.md" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    NSDictionary *info = [spec matchInfoForPath:@"docs/something.coffee.md" type:ATPathSpecEntryTypeFile];
    XCTAssertNotNil(info);
    XCTAssertNil(info[ATPathSpecMatchInfoMatchedStaticName]);
    XCTAssertEqualObjects(info[ATPathSpecMatchInfoMatchedSuffix], @".coffee.md");
}

- (void)testPatternMatch {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"*o*/READ*.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    NSDictionary *info = [spec matchInfoForPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile];
    XCTAssertNotNil(info);
    XCTAssertNil(info[ATPathSpecMatchInfoMatchedStaticName]);
    XCTAssertEqualObjects(info[ATPathSpecMatchInfoMatchedSuffix], @".txt");
}

- (void)testMaskMatchInPath {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"*.txt" syntaxOptions:ATPathSpecSyntaxFlavorGitignore];
    NSDictionary *info = [spec matchInfoForPath:@"docs.txt/README.md" type:ATPathSpecEntryTypeFile];
    XCTAssertNotNil(info);
    XCTAssertNil(info[ATPathSpecMatchInfoMatchedStaticName]);
    XCTAssertNil(info[ATPathSpecMatchInfoMatchedSuffix]);
}

- (void)testPatternMatchWithNegation {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"*.txt !~*" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    NSDictionary *info = [spec matchInfoForPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile];
    XCTAssertNotNil(info);
    XCTAssertNil(info[ATPathSpecMatchInfoMatchedStaticName]);
    XCTAssertEqualObjects(info[ATPathSpecMatchInfoMatchedSuffix], @".txt");
}

- (void)testWildMatchWithNegation {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"READ* !~*.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    NSDictionary *info = [spec matchInfoForPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile];
    XCTAssertNotNil(info);
    XCTAssertNil(info[ATPathSpecMatchInfoMatchedStaticName]);
    XCTAssertNil(info[ATPathSpecMatchInfoMatchedSuffix]);
}

- (void)testStaticAndPatternIntersectionMatch {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"README.txt & *.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    NSDictionary *info = [spec matchInfoForPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile];
    XCTAssertNotNil(info);
    XCTAssertEqualObjects(info[ATPathSpecMatchInfoMatchedStaticName], @"README.txt");
    XCTAssertEqualObjects(info[ATPathSpecMatchInfoMatchedSuffix], @".txt");
}

@end
