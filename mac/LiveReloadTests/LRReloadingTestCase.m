#import "LRIntegrationTestCase.h"


@interface LRReloadingTestCase : LRIntegrationTestCase
@end


@implementation LRReloadingTestCase

- (void)testExample {
    XCTAssertNil([self runProjectTestNamed:@"reloading/simple_html" options:LRTestOptionNone], @"Failed");
}

@end
