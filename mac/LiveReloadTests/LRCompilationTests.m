
#import "LRIntegrationTestCase.h"


@interface LRCompilationTests : LRIntegrationTestCase

@end


@implementation LRCompilationTests

- (void)testHamlSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/haml_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testHamlErrorSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/haml_error_simple" options:LRTestOptionNone], @"Failed");
}

- (void)testLessSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/less_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testLessImports {
    XCTAssertNil([self runProjectTestNamed:@"compilers/less_imports" options:LRTestOptionNone], @"Failed");
}
- (void)testLessImportsReference {
    XCTAssertNil([self runProjectTestNamed:@"compilers/less_imports_reference" options:LRTestOptionNone], @"Failed");
}
- (void)testLessVersion3 {
    XCTAssertNil([self runProjectTestNamed:@"compilers/less_version_3" options:LRTestOptionNone], @"Failed");
}
- (void)testLessVersion4 {
    XCTAssertNil([self runProjectTestNamed:@"compilers/less_version_4" options:LRTestOptionNone], @"Failed");
}
- (void)testLessVersion5 {
    XCTAssertNil([self runProjectTestNamed:@"compilers/less_version_5" options:LRTestOptionNone], @"Failed");
}
- (void)testLessErrorSimple1 {
    XCTAssertNil([self runProjectTestNamed:@"compilers/less_error_simple_1" options:LRTestOptionNone], @"Failed");
}
- (void)testLessErrorImported {
    XCTAssertNil([self runProjectTestNamed:@"compilers/less_error_imported" options:LRTestOptionNone], @"Failed");
}

- (void)testEcoSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/eco_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testEcoErrorSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/eco_error_simple" options:LRTestOptionNone], @"Failed");
}

- (void)testCoffeeScriptSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/coffeescript_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testCoffeeScriptLiterate {
    XCTAssertNil([self runProjectTestNamed:@"compilers/coffeescript_literate" options:LRTestOptionNone], @"Failed");
}
- (void)testCoffeeScriptLiterateMd {
    XCTAssertNil([self runProjectTestNamed:@"compilers/coffeescript_literate_md" options:LRTestOptionNone], @"Failed");
}
- (void)testCoffeeScriptError {
    XCTAssertNil([self runProjectTestNamed:@"compilers/coffeescript_error" options:LRTestOptionNone], @"Failed");
}

- (void)testIcedCoffeeScriptSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/icedcoffeescript_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testIcedCoffeeScriptLiterate {
    XCTAssertNil([self runProjectTestNamed:@"compilers/icedcoffeescript_literate" options:LRTestOptionNone], @"Failed");
}
- (void)testIcedCoffeeScriptLiterateMd {
    XCTAssertNil([self runProjectTestNamed:@"compilers/icedcoffeescript_literate_md" options:LRTestOptionNone], @"Failed");
}
- (void)testIcedCoffeeScriptError {
    XCTAssertNil([self runProjectTestNamed:@"compilers/icedcoffeescript_error" options:LRTestOptionNone], @"Failed");
}

- (void)testJadeSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/jade_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testJadeFilterMarkdown {
    XCTAssertNil([self runProjectTestNamed:@"compilers/jade_filter_markdown" options:LRTestOptionNone], @"Failed");
}
- (void)testJadeErrorSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/jade_error_simple" options:LRTestOptionNone], @"Failed");
}

- (void)testSassSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/sass_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testSassIndented {
    XCTAssertNil([self runProjectTestNamed:@"compilers/sass_indented" options:LRTestOptionNone], @"Failed");
}
- (void)testSassErrorSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/sass_error_simple" options:LRTestOptionNone], @"Failed");
}

- (void)testSlimSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/slim_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testSlimErrorSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/slim_error_simple" options:LRTestOptionNone], @"Failed");
}

- (void)testStylusSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/stylus_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testStylusNib {
    XCTAssertNil([self runProjectTestNamed:@"compilers/stylus_nib" options:LRTestOptionNone], @"Failed");
}
- (void)testStylusErrorSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/stylus_error_simple" options:LRTestOptionNone], @"Failed");
}

- (void)testTypeScriptSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/typescript_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testTypeScriptErrorSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/typescript_error_simple" options:LRTestOptionNone], @"Failed");
}

- (void)testCompassSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/compass_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testCompassErrorSimple {
    XCTAssertNil([self runProjectTestNamed:@"compilers/compass_error_simple" options:LRTestOptionNone], @"Failed");
}

@end
