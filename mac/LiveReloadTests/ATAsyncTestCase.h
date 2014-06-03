
#import <XCTest/XCTest.h>


@interface XCTestCase (ATAsyncTest)

- (void)waitWithTimeout:(NSTimeInterval)timeout;
- (void)waitForCondition:(BOOL(^)())conditionBlock withTimeout:(NSTimeInterval)timeout;
- (dispatch_block_t)completionBlock;
- (void)done;

@end
