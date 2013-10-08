
#import "ScriptInvocationAction.h"

#import "Project.h"
#import "Plugin.h"
#import "LRFile2.h"
#import "ScriptInvocationStep.h"


@implementation ScriptInvocationAction

+ (void)validateActionType:(ActionType *)type {
    // TODO: validate errorSpecs?
}

- (void)compileFile:(LRFile2 *)file inProject:(Project *)project completionHandler:(UserScriptCompletionHandler)completionHandler {
    ScriptInvocationStep *step = [ScriptInvocationStep new];
    step.project = project;
    [step addValue:project.path forSubstitutionKey:@"project_dir"];

    [self configureStep:step forFile:file];

    step.completionHandler = ^(ScriptInvocationStep *step) {
        [self didCompleteCompilationStep:step forFile:file];
        completionHandler(YES, step.output, step.error);
    };

    NSLog(@"%@: %@", self.label, file.absolutePath);
    [step invoke];
}

- (void)configureStep:(ScriptInvocationStep *)step forFile:(LRFile2 *)file {
    step.commandLine = self.type.options[@"cmdline"];
    [step addValue:self.type.plugin.path forSubstitutionKey:@"plugin"];
}

- (void)didCompleteCompilationStep:(ScriptInvocationStep *)step forFile:(LRFile2 *)file {
}

- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler {
}

@end
