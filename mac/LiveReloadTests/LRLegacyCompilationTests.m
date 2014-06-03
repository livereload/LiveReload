
#import "LRIntegrationTestCase.h"


@interface LRLegacyCompilationTests : LRIntegrationTestCase
@end


@implementation LRLegacyCompilationTests

// TODO re-enable these tests when we can automatically migrate 2.x compilation settings

#if 0

- (void)testHamlSimple {
    XCTAssertNil([self runProjectTestNamed:@"haml_simple" options:LRTestOptionLegacy], @"Failed");
}

- (void)testLessSimple {
    XCTAssertNil([self runProjectTestNamed:@"less_simple" options:LRTestOptionLegacy], @"Failed");
}
- (void)testLessImports {
    XCTAssertNil([self runProjectTestNamed:@"less_imports" options:LRTestOptionLegacy], @"Failed");
}
- (void)testLessImportsReference {
    XCTAssertNil([self runProjectTestNamed:@"less_imports_reference" options:LRTestOptionLegacy], @"Failed");
}
- (void)testLessVersion5 {
    XCTAssertNil([self runProjectTestNamed:@"less_version_5" options:LRTestOptionLegacy], @"Failed");
}

- (void)testEcoSimple {
    XCTAssertNil([self runProjectTestNamed:@"eco_simple" options:LRTestOptionLegacy], @"Failed");
}

- (void)testCoffeeScriptSimple {
    XCTAssertNil([self runProjectTestNamed:@"coffeescript_simple" options:LRTestOptionLegacy], @"Failed");
}
- (void)testCoffeeScriptLiterate {
    XCTAssertNil([self runProjectTestNamed:@"coffeescript_literate" options:LRTestOptionLegacy], @"Failed");
}
- (void)XXXtestCoffeeScriptLiterateMd {
    XCTAssertNil([self runProjectTestNamed:@"coffeescript_literate_md" options:LRTestOptionLegacy], @"Failed");
}

- (void)testIcedCoffeeScriptSimple {
    XCTAssertNil([self runProjectTestNamed:@"icedcoffeescript_simple" options:LRTestOptionLegacy], @"Failed");
}
- (void)XXXtestIcedCoffeeScriptLiterate {
    XCTAssertNil([self runProjectTestNamed:@"icedcoffeescript_literate" options:LRTestOptionLegacy], @"Failed");
}
- (void)XXXtestIcedCoffeeScriptLiterateMd {
    XCTAssertNil([self runProjectTestNamed:@"icedcoffeescript_literate_md" options:LRTestOptionLegacy], @"Failed");
}

- (void)testJadeSimple {
    XCTAssertNil([self runProjectTestNamed:@"jade_simple" options:LRTestOptionLegacy], @"Failed");
}
- (void)testJadeFilterMarkdown {
    XCTAssertNil([self runProjectTestNamed:@"jade_filter_markdown" options:LRTestOptionLegacy], @"Failed");
}

- (void)testSassSimple {
    XCTAssertNil([self runProjectTestNamed:@"sass_simple" options:LRTestOptionLegacy], @"Failed");
}
- (void)testSassIndented {
    XCTAssertNil([self runProjectTestNamed:@"sass_indented" options:LRTestOptionLegacy], @"Failed");
}

- (void)testSlimSimple {
    XCTAssertNil([self runProjectTestNamed:@"slim_simple" options:LRTestOptionLegacy], @"Failed");
}

- (void)testStylusSimple {
    XCTAssertNil([self runProjectTestNamed:@"stylus_simple" options:LRTestOptionLegacy], @"Failed");
}
- (void)testStylusNib {
    XCTAssertNil([self runProjectTestNamed:@"stylus_nib" options:LRTestOptionLegacy], @"Failed");
}

- (void)testTypeScriptSimple {
    XCTAssertNil([self runProjectTestNamed:@"typescript_simple" options:LRTestOptionLegacy], @"Failed");
}

#endif

@end
