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


@interface XCTestCase (ATAsyncTest)

- (void)waitWithTimeout:(NSTimeInterval)timeout;
- (void)done;

@end

@implementation XCTestCase (ATAsyncTest)

static volatile BOOL _ATAsyncTest_done;

- (void)waitWithTimeout:(NSTimeInterval)timeout {
    _ATAsyncTest_done = NO;
    NSDate *cutoff = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while (!_ATAsyncTest_done && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:cutoff])
        NSLog(@"Still waiting...");
    NSAssert([[NSDate date] compare:cutoff] == NSOrderedAscending, @"Timeout");
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
    NSLog(@"Setting up...");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [self done];
    });
    [self waitWithTimeout:7.0];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testExample {
    LRTest *test = [[LRTest alloc] initWithFolderURL:[NSURL URLWithString:[@"~/dev/livereload/support/examples/haml_simple" stringByExpandingTildeInPath]]];
    test.completionBlock = self.completionBlock;
    [test run];

    [self waitWithTimeout:3.0];
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}


@end
