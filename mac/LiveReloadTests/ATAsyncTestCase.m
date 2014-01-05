
#import "ATAsyncTestCase.h"


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
