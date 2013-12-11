//
//  LiveReloadTests.m
//  LiveReloadTests
//
//  Created by Andrey Tarantsov on 11.12.2013.
//
//

#import <XCTest/XCTest.h>

#import "LRTest.h"
#import "LiveReloadAppDelegate.h"
#import "AppState.h"
#import "LRPackageManager.h"
#import "PluginManager.h"
#import "Plugin.h"
#import "LRPackageContainer.h"

#import "ATFunctionalStyle.h"


@interface XCTestCase (ATAsyncTest)

- (void)waitWithTimeout:(NSTimeInterval)timeout;
- (void)done;

@end

@implementation XCTestCase (ATAsyncTest)

static volatile BOOL _ATAsyncTest_done;

- (void)waitForCondition:(BOOL(^)())conditionBlock withTimeout:(NSTimeInterval)timeout {
    NSDate *cutoff = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while (!conditionBlock() && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:cutoff])
        NSLog(@"Still waiting...");
    if (!conditionBlock()) {
        NSAssert([[NSDate date] compare:cutoff] == NSOrderedAscending, @"Timeout");
    }
}

- (void)waitWithTimeout:(NSTimeInterval)timeout {
    _ATAsyncTest_done = NO;
    NSDate *cutoff = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while (!_ATAsyncTest_done && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:cutoff])
        NSLog(@"Still waiting...");
    if (!_ATAsyncTest_done) {
        NSAssert([[NSDate date] compare:cutoff] == NSOrderedAscending, @"Timeout");
    }
}

- (dispatch_block_t)completionBlock {
    return ^{
        [self done];
    };
}

- (void)done {
    dispatch_async(dispatch_get_main_queue(), ^{
        _ATAsyncTest_done = YES;
    });
}


@end


@interface LiveReloadTests : XCTestCase

@end


@implementation LiveReloadTests

+ (void)setUp {
    [super setUp];
}

- (void)setUp {
    [super setUp];
    NSLog(@"Waiting for initialization to finish...");
    [self waitForCondition:^BOOL{
        NSArray *packageContainers = [[PluginManager sharedPluginManager].plugins valueForKeyPath:@"@unionOfArrays.bundledPackageContainers"];
        return (packageContainers.count > 0) && [packageContainers all:^BOOL(LRPackageContainer *container) {
            return !container.updateInProgress;
        }];
    } withTimeout:3000];
    NSLog(@"Initialization finished.");
}

- (void)tearDown {
    [super tearDown];
}

- (void)testExample {
    LRTest *test = [[LRTest alloc] initWithFolderURL:[NSURL fileURLWithPath:[@"~/dev/livereload/support/examples/haml_simple" stringByExpandingTildeInPath]]];
    test.completionBlock = self.completionBlock;
    [test run];

    [self waitWithTimeout:3.0];
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}


@end
