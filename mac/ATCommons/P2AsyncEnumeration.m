
#import "P2AsyncEnumeration.h"

@implementation NSArray (P2AsyncEnumeration)

- (void)p2_enumerateObjectsAsynchronouslyUsingBlock:(void (^)(id obj, NSUInteger idx,  BOOL *stop, dispatch_block_t callback))block completionBlock:(dispatch_block_t)completionBlock {
    [self p2_enumerateObjectsAsynchronouslyUsingBlock:block completionBlock:completionBlock usingQueue:dispatch_get_current_queue()];
}

- (void)p2_enumerateObjectsAsynchronouslyUsingBlock:(void (^)(id obj, NSUInteger idx,  BOOL *stop, dispatch_block_t callback))block completionBlock:(dispatch_block_t)completionBlock usingQueue:(dispatch_queue_t)queue {
    __block NSArray *items = [self copy];
    __block NSUInteger index = 0;
    __block BOOL stop = NO;

    // retain cycle is intentional here
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    __block dispatch_block_t iterationCallback;
    iterationCallback = [^{
        dispatch_async(queue, ^{
            if (stop || items.count == 0) {
                iterationCallback = nil;
                completionBlock();
            } else {
                id obj = [items firstObject];
                items = [items subarrayWithRange:NSMakeRange(1, items.count - 1)];
                NSUInteger idx = index++;
                block(obj, idx, &stop, iterationCallback);
            }
        });
    } copy];
#pragma clang diagnostic pop

    iterationCallback();
}

@end
