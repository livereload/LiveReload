
#import "LRProjectTargetResult.h"
#import "Action.h"
#import "Project.h"
#import "LRBuildResult.h"


@interface LRProjectTargetResult ()

@end


@implementation LRProjectTargetResult

- (instancetype)initWithAction:(Action *)action modifiedFiles:(NSArray *)modifiedFiles {
    self = [super initWithAction:action];
    if (self) {
        _modifiedFiles = [modifiedFiles copy];
    }
    return self;
}

- (void)invokeWithCompletionBlock:(dispatch_block_t)completionBlock build:(LRBuildResult *)build {
    LROperationResult *result = [self newResult];
    [self.action invokeForProject:self.project withModifiedFiles:_modifiedFiles result:result completionHandler:^{
        [build addOperationResult:result forTarget:self key:[NSString stringWithFormat:@"%@.postproc", self.project.path]];
        completionBlock();
    }];
}

@end
