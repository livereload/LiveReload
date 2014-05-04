
#import "Action.h"


@class ScriptInvocationStep;
@class LRFile2;


@interface ScriptInvocationActionType : ActionType
@end


@interface ScriptInvocationAction : Action

// override points
- (void)configureStep:(ScriptInvocationStep *)step forFile:(LRFile2 *)file;
- (void)didCompleteCompilationStep:(ScriptInvocationStep *)step forFile:(LRFile2 *)file;

@end
