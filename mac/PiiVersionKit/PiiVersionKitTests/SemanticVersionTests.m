#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
@import PiiVersionKit;

@interface SemanticVersionTests : XCTestCase

@end

@implementation SemanticVersionTests

- (void)testSemanticVersion {
    LRSemanticVersion *version = [[LRSemanticVersionSpace semanticVersionSpace] versionWithString:@"1.2.3"];
    XCTAssertEqual(version.major, 1);
    XCTAssertEqual(version.minor, 2);
    XCTAssertEqual(version.patch, 3);
}

@end
