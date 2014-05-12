
#import <Foundation/Foundation.h>


@class Project;
@class Action;
@class LROperationResult;


@interface LRTargetResult : NSObject

- (instancetype)initWithAction:(Action *)action;

@property (nonatomic, readonly) Project *project;
@property (nonatomic, readonly) Action *action;

- (void)invokeWithCompletionBlock:(dispatch_block_t)completionBlock;

- (LROperationResult *)newResult;

@end
