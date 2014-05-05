
#import "ScriptInvocationAction.h"

#import "Project.h"
#import "Plugin.h"
#import "LRFile2.h"
#import "ScriptInvocationStep.h"
#import "LROption.h"
#import "LRActionVersion.h"
#import "LRActionManifest.h"
#import "LRPackageSet.h"
#import "LRPackage.h"
#import "LRPackageContainer.h"
#import "LRPackageType.h"
#import "LRVersion.h"
#import "Errors.h"


@implementation ScriptInvocationActionType {
}

@end


@implementation ScriptInvocationAction

- (void)compileFile:(LRFile2 *)file inProject:(Project *)project completionHandler:(UserScriptCompletionHandler)completionHandler {
    if (!self.effectiveVersion) {
        return completionHandler(NO, nil, [self missingEffectiveVersionError]);
    }

    ScriptInvocationStep *step = [ScriptInvocationStep new];
    [self configureStep:step forFile:file];

    step.completionHandler = ^(ScriptInvocationStep *step) {
        [self didCompleteCompilationStep:step forFile:file];
        completionHandler(YES, step.output, step.error);
    };

    NSLog(@"%@: %@", self.label, file.absolutePath);
    [step invoke];
}

- (void)configureStep:(ScriptInvocationStep *)step forFile:(LRFile2 *)file {
    [self configureStep:step];
}

- (void)didCompleteCompilationStep:(ScriptInvocationStep *)step forFile:(LRFile2 *)file {
}

- (void)invokeForProject:(Project *)project withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler {
}

@end
