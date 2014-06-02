
#import "LRIntegrationTestCase.h"


@interface LRCustomActionTests : LRIntegrationTestCase

@end


@implementation LRCustomActionTests

- (void)testCommandSimple {
    XCTAssertNil([self runProjectTestNamed:@"custom_actions/command_simple" options:LRTestOptionNone], @"Failed");
}
- (void)testCommandOncePerBuild {
    XCTAssertNil([self runProjectTestNamed:@"custom_actions/command_once_per_build" options:LRTestOptionNone], @"Failed");
}
- (void)testCommandLoop {
    XCTAssertNil([self runProjectTestNamed:@"custom_actions/command_loop" options:LRTestOptionNone], @"Failed");
}

@end
