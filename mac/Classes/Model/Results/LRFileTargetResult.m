
#import "LRFileTargetResult.h"
#import "Action.h"
#import "LRFile2.h"
#import "Project.h"


@interface LRFileTargetResult ()

@end


@implementation LRFileTargetResult

- (instancetype)initWithAction:(Action *)action sourceFile:(LRFile2 *)sourceFile {
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
            [self.action compileFile:_sourceFile inProject:self.project completionHandler:^(BOOL invoked, ToolOutput *output, NSError *error) {
                if (error) {
                    NSLog(@"Error compiling %@: %@ - %ld - %@", _sourceFile.relativePath, error.domain, (long)error.code, error.localizedDescription);
                }
                [self.project displayCompilationError:output key:[NSString stringWithFormat:@"%@.%@", self.project.path, _sourceFile.relativePath]];
                completionBlock();
            }];
        }
    } else {
        completionBlock();
    }
}

@end
