
#import "ScriptInvocationAction.h"

#import "Project.h"
#import "Plugin.h"
#import "LRFile2.h"
#import "ScriptInvocationStep.h"
#import "LROption.h"


@implementation ScriptInvocationActionType {
}

- (void)initializeWithOptions {
    [super initializeWithOptions];
}

@end


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
    step.manifest = self.type.options;
    [step addValue:self.type.plugin.path forSubstitutionKey:@"plugin"];

    NSMutableArray *additionalArguments = [NSMutableArray new];
    for (LROption *option in [self createOptions]) {
        [additionalArguments addObjectsFromArray:option.commandLineArguments];
    }
    [additionalArguments addObjectsFromArray:self.customArguments];

    [step addValue:[additionalArguments copy] forSubstitutionKey:@"additional"];
}

- (void)didCompleteCompilationStep:(ScriptInvocationStep *)step forFile:(LRFile2 *)file {
}

- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler {
}

@end
