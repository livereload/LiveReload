
#import <Foundation/Foundation.h>

@interface NSArray (P2AsyncEnumeration)

- (void)p2_enumerateObjectsAsynchronouslyUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop, dispatch_block_t callback))block completionBlock:(dispatch_block_t)completionBlock;
- (void)p2_enumerateObjectsAsynchronouslyUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop, dispatch_block_t callback))block completionBlock:(dispatch_block_t)completionBlock usingQueue:(dispatch_queue_t)queue;

@end
