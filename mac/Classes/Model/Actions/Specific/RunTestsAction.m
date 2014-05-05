
#import "RunTestsAction.h"
#import "ScriptInvocationStep.h"
#import "Project.h"


@interface RunTestsAction ()

@end


@implementation RunTestsAction

- (NSString *)label {
    return self.type.name;
}

- (void)invokeForProject:(Project *)project withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler {
    if (!self.effectiveVersion) {
        return completionHandler(NO, nil, [self missingEffectiveVersionError]);
    }

    ScriptInvocationStep *step = [ScriptInvocationStep new];
    [self configureStep:step];

    step.completionHandler = ^(ScriptInvocationStep *step) {
//        [self didCompleteCompilationStep:step forFile:file];
        completionHandler(YES, step.output, step.error);
    };

    NSLog(@"%@: %@", self.label, project.rootURL.path);
    [step invoke];
}

@end
