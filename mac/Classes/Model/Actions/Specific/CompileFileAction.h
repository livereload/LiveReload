
#import "ScriptInvocationAction.h"

@interface CompileFileAction : ScriptInvocationAction

@property(nonatomic, copy) NSString *compilerName;

@property(nonatomic, strong) FilterOption *outputFilterOption;

@end
