
#import "LRIntegrationTestCase.h"


@interface LRCustomActionTests : LRIntegrationTestCase

@end


@implementation LRCustomActionTests

- (void)testCommandSimple {
    XCTAssertNil([self runProjectTestNamed:@"custom_actions/command_simple" options:LRTestOptionNone], @"Failed");
}

@end
