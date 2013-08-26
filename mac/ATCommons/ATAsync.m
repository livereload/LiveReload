
#import "ATAsync.h"

@implementation NSArray (ATAsync)

- (void)enumerateObjectsAsynchronouslyUsingBlock:(void (^)(id obj, NSUInteger idx, void (^callback)(BOOL stop)))block completionBlock:(void(^)())completionBlock {
    [self enumerateObjectsAsynchronouslyUsingBlock:block completionBlock:completionBlock usingQueue:dispatch_get_current_queue()];
}

- (void)enumerateObjectsAsynchronouslyUsingBlock:(void (^)(id obj, NSUInteger idx, void (^callback)(BOOL stop)))block completionBlock:(void(^)())completionBlock usingQueue:(dispatch_queue_t)queue {
    __block NSArray *items = [self copy];
    __block NSUInteger index = 0;

    // retain cycle is intentional here
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    __block void (^iterationCallback)(BOOL stop);
    iterationCallback = [^(BOOL stop){
        dispatch_async(queue, ^{
            if (stop || items.count == 0) {
                iterationCallback = nil;
                completionBlock();
            } else {
                id obj = [items firstObject];
                items = [items subarrayWithRange:NSMakeRange(1, items.count - 1)];
                NSUInteger idx = index++;
                block(obj, idx, iterationCallback);
            }
        });
    } copy];
#pragma clang diagnostic pop

    iterationCallback(NO);
}

@end
