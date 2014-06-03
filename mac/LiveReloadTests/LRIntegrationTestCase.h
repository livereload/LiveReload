
#import <XCTest/XCTest.h>

#import "LRSelfTest.h"
#import "LiveReloadAppDelegate.h"
#import "AppState.h"
#import "LRPackageManager.h"
#import "PluginManager.h"
#import "Plugin.h"
#import "LRPackageContainer.h"

#import "ATFunctionalStyle.h"


@interface LRIntegrationTestCase : XCTestCase

- (NSError *)runProjectTestNamed:(NSString *)name options:(LRTestOptions)options;

@end
