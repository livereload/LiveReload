
#import <Foundation/Foundation.h>


@class Project;
@class Action;
@class LROperationResult;
@class LRBuild;


@interface LRTargetResult : NSObject

- (instancetype)initWithAction:(Action *)action;

@property (nonatomic, readonly) Project *project;
@property (nonatomic, readonly) Action *action;

- (void)invokeWithCompletionBlock:(dispatch_block_t)completionBlock build:(LRBuild *)build;

- (LROperationResult *)newResult;

@end
