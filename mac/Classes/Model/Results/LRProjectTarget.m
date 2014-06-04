
#import "LRProjectTarget.h"
#import "Action.h"
#import "Project.h"
#import "LRBuild.h"


@interface LRProjectTarget ()

@end


@implementation LRProjectTarget

- (instancetype)initWithAction:(Action *)action modifiedFiles:(NSArray *)modifiedFiles {
    self = [super initWithAction:action];
    if (self) {
        _modifiedFiles = [modifiedFiles copy];
    }
    return self;
}

- (void)invokeWithCompletionBlock:(dispatch_block_t)completionBlock build:(LRBuild *)build {
    LROperationResult *result = [self newResult];
    [self.action invokeForProject:self.project withModifiedFiles:_modifiedFiles result:result completionHandler:^{
        [build addOperationResult:result forTarget:self key:[NSString stringWithFormat:@"%@.postproc", self.project.path]];
        completionBlock();
    }];
}

@end
