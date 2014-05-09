
#import "LRProjectTargetResult.h"
#import "Action.h"
#import "Project.h"


@interface LRProjectTargetResult ()

@end


@implementation LRProjectTargetResult

- (instancetype)initWithAction:(Action *)action modifiedPaths:(NSSet *)modifiedPaths {
    self = [super initWithAction:action];
    if (self) {
        _modifiedPaths = [modifiedPaths copy];
    }
    return self;
}

- (void)invokeWithCompletionBlock:(dispatch_block_t)completionBlock {
    [self.action invokeForProject:self.project withModifiedFiles:_modifiedPaths completionHandler:^(BOOL invoked, ToolOutput *output, NSError *error) {
        [self.project displayCompilationError:output key:[NSString stringWithFormat:@"%@.postproc", self.project.path]];
        completionBlock();
    }];
}

@end
