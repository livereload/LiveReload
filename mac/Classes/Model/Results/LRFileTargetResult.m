
#import "LRFileTargetResult.h"
#import "Action.h"
#import "LRProjectFile.h"
#import "Project.h"
#import "LROperationResult.h"


@interface LRFileTargetResult ()

@end


@implementation LRFileTargetResult

- (instancetype)initWithAction:(Action *)action sourceFile:(LRProjectFile *)sourceFile {
    self = [super initWithAction:action];
    if (self) {
        _sourceFile = sourceFile;
    }
    return self;
}

- (void)invokeWithCompletionBlock:(dispatch_block_t)completionBlock {
    if ([self.action shouldInvokeForFile:_sourceFile]) {
        if (!_sourceFile.exists) {
            [self.action handleDeletionOfFile:_sourceFile inProject:self.project];
            completionBlock();
        } else {
            LROperationResult *result = [self newResult];
            result.defaultMessageFile = _sourceFile;
            [self.action compileFile:_sourceFile inProject:self.project result:(LROperationResult *)result completionHandler:^{
                if (result.invocationError) {
                    NSLog(@"Error compiling %@: %@ - %ld - %@", _sourceFile.relativePath, result.invocationError.domain, (long)result.invocationError.code, result.invocationError.localizedDescription);
                }
                [self.project displayResult:result key:[NSString stringWithFormat:@"%@.%@", self.project.path, _sourceFile.relativePath]];
                completionBlock();
            }];
        }
    } else {
        completionBlock();
    }
}

@end
