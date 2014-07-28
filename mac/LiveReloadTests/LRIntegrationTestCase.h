#import <XCTest/XCTest.h>

#import "LRSelfTest.h"
#import "LiveReloadAppDelegate.h"
#import "AppState.h"
@import PackageManagerKit;
#import "LiveReload-Swift-x.h"
#import "Plugin.h"

#import "ATFunctionalStyle.h"


@interface LRIntegrationTestCase : XCTestCase

- (NSError *)runProjectTestNamed:(NSString *)name options:(LRTestOptions)options;

@end
