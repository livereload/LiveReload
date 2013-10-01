
#import "Action.h"


@class ScriptInvocationStep;
@class LRFile2;


@interface ScriptInvocationAction : Action

// override point
- (void)configureStep:(ScriptInvocationStep *)step forFile:(LRFile2 *)file;

@end
