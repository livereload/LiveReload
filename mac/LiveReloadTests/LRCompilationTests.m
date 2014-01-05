
#import "LRIntegrationTestCase.h"


@interface LRCompilationTests : LRIntegrationTestCase

@end


@implementation LRCompilationTests

- (void)testHamlSimple {
    XCTAssertNil([self runProjectTestNamed:@"haml_simple" options:LRTestOptionNone], @"Failed");
}

- (void)testLessSimple {
    XCTAssertNil([self runProjectTestNamed:@"less_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testLessImports {
    XCTAssertNil([self runProjectTestNamed:@"less_imports" options:LRTestOptionNone], @"Failed");
}
- (void)testLessImportsReference {
    XCTAssertNil([self runProjectTestNamed:@"less_imports_reference" options:LRTestOptionNone], @"Failed");
}
- (void)testLessVersion3 {
    XCTAssertNil([self runProjectTestNamed:@"less_version_3" options:LRTestOptionNone], @"Failed");
}
- (void)testLessVersion4 {
    XCTAssertNil([self runProjectTestNamed:@"less_version_4" options:LRTestOptionNone], @"Failed");
}
- (void)testLessVersion5 {
    XCTAssertNil([self runProjectTestNamed:@"less_version_5" options:LRTestOptionNone], @"Failed");
}

- (void)testEcoSimple {
    XCTAssertNil([self runProjectTestNamed:@"eco_simple" options:LRTestOptionNone], @"Failed");
}

- (void)testCoffeeScriptSimple {
    XCTAssertNil([self runProjectTestNamed:@"coffeescript_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testCoffeeScriptLiterate {
    XCTAssertNil([self runProjectTestNamed:@"coffeescript_literate" options:LRTestOptionNone], @"Failed");
}
- (void)testCoffeeScriptLiterateMd {
    XCTAssertNil([self runProjectTestNamed:@"coffeescript_literate_md" options:LRTestOptionNone], @"Failed");
}

- (void)testIcedCoffeeScriptSimple {
    XCTAssertNil([self runProjectTestNamed:@"icedcoffeescript_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testIcedCoffeeScriptLiterate {
    XCTAssertNil([self runProjectTestNamed:@"icedcoffeescript_literate" options:LRTestOptionNone], @"Failed");
}
- (void)testIcedCoffeeScriptLiterateMd {
    XCTAssertNil([self runProjectTestNamed:@"icedcoffeescript_literate_md" options:LRTestOptionNone], @"Failed");
}

- (void)testJadeSimple {
    XCTAssertNil([self runProjectTestNamed:@"jade_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testJadeFilterMarkdown {
    XCTAssertNil([self runProjectTestNamed:@"jade_filter_markdown" options:LRTestOptionNone], @"Failed");
}

- (void)testSassSimple {
    XCTAssertNil([self runProjectTestNamed:@"sass_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testSassIndented {
    XCTAssertNil([self runProjectTestNamed:@"sass_indented" options:LRTestOptionNone], @"Failed");
}

- (void)testSlimSimple {
    XCTAssertNil([self runProjectTestNamed:@"slim_simple" options:LRTestOptionNone], @"Failed");
}

- (void)testStylusSimple {
    XCTAssertNil([self runProjectTestNamed:@"stylus_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testStylusNib {
    XCTAssertNil([self runProjectTestNamed:@"stylus_nib" options:LRTestOptionNone], @"Failed");
}

- (void)testTypeScriptSimple {
    XCTAssertNil([self runProjectTestNamed:@"typescript_simple" options:LRTestOptionNone], @"Failed");
}

@end
