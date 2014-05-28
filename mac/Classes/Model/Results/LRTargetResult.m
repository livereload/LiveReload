
#import "LRTargetResult.h"
#import "Action.h"
#import "LROperationResult.h"


@interface LRTargetResult ()

@end


@implementation LRTargetResult

- (instancetype)initWithAction:(Action *)action {
    self = [super init];
    if (self) {
        _action = action;
    }
    return self;
}

- (Project *)project {
    return _action.project;
}

- (void)invokeWithCompletionBlock:(dispatch_block_t)completionBlock build:(LRBuildResult *)build {
    abort();
}

- (LROperationResult *)newResult {
    LROperationResult *result = [LROperationResult new];
    [_action configureResult:result];
    return result;
}

@end
