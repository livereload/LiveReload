
#import "Action.h"


@class ScriptInvocationStep;
@class LRProjectFile;


@interface ScriptInvocationActionType : ActionType
@end


@interface ScriptInvocationAction : Action

// override points
- (void)configureStep:(ScriptInvocationStep *)step forFile:(LRProjectFile *)file;
- (void)didCompleteCompilationStep:(ScriptInvocationStep *)step forFile:(LRProjectFile *)file;

@end
