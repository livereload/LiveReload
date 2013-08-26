
#import <Foundation/Foundation.h>

@interface NSArray (ATAsync)

- (void)enumerateObjectsAsynchronouslyUsingBlock:(void (^)(id obj, NSUInteger idx, void (^callback)(BOOL stop)))block completionBlock:(void(^)())completionBlock;
- (void)enumerateObjectsAsynchronouslyUsingBlock:(void (^)(id obj, NSUInteger idx, void (^callback)(BOOL stop)))block completionBlock:(void(^)())completionBlock usingQueue:(dispatch_queue_t)queue;

@end
