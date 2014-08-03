@import XCTest;
@import LRCommons;
@import PackageManagerKit;

#import "LRSelfTest.h"
#import "LiveReloadAppDelegate.h"
#import "AppState.h"
#import "LiveReload-Swift-x.h"
#import "Plugin.h"


@interface LRIntegrationTestCase : XCTestCase

- (NSError *)runProjectTestNamed:(NSString *)name options:(LRTestOptions)options;

@end
