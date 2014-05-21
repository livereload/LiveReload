#import "LRIntegrationTestCase.h"


@interface LRReloadingTestCase : LRIntegrationTestCase
@end


@implementation LRReloadingTestCase

- (void)testSimpleHtml {
    XCTAssertNil([self runProjectTestNamed:@"reloading/simple_html" options:LRTestOptionNone], @"Failed");
}

- (void)testSimpleCss {
    XCTAssertNil([self runProjectTestNamed:@"reloading/simple_css" options:LRTestOptionNone], @"Failed");
}

- (void)testCompiledLess {
    XCTAssertNil([self runProjectTestNamed:@"reloading/compiled_less" options:LRTestOptionNone], @"Failed");
}

- (void)testFakeLess {
    XCTAssertNil([self runProjectTestNamed:@"reloading/fake_less" options:LRTestOptionNone], @"Failed");
}

- (void)testSpecialReloadAllStylesheets {
    XCTAssertNil([self runProjectTestNamed:@"reloading/special_reload_all_stylesheets" options:LRTestOptionNone], @"Failed");
}

@end
