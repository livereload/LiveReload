
#import "RunTestsAction.h"
#import "ScriptInvocationStep.h"
#import "Project.h"
#import "LRTestRunner.h"


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

    LRTRRun *run = [[LRTRRun alloc] init];
    LRTRProtocolParser *parser = [[LRTRTestAnythingProtocolParser alloc] init];
    parser.delegate = run;

    ScriptInvocationStep *step = [ScriptInvocationStep new];
    [self configureStep:step];

    step.completionHandler = ^(ScriptInvocationStep *step) {
        [parser finish];
        NSLog(@"Tests = %@", run.tests);
//        [self didCompleteCompilationStep:step forFile:file];
        completionHandler(YES, step.output, step.error);
    };

    step.outputLineBlock = ^(NSString *line) {
        NSLog(@"Testing output line: %@", [line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]);
        [parser processLine:line];
    };

    NSLog(@"%@: %@", self.label, project.rootURL.path);
    [step invoke];
}

@end
