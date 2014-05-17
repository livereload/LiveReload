
#import "ScriptInvocationAction.h"

#import "Project.h"
#import "Plugin.h"
#import "LRProjectFile.h"
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
#import "LROperationResult.h"


@implementation ScriptInvocationActionType {
}

@end


@implementation ScriptInvocationAction

- (void)compileFile:(LRProjectFile *)file inProject:(Project *)project result:(LROperationResult *)result completionHandler:(dispatch_block_t)completionHandler {
    if (!self.effectiveVersion) {
        [result completedWithInvocationError:[self missingEffectiveVersionError]];
        return completionHandler();
    }

    ScriptInvocationStep *step = [ScriptInvocationStep new];
    step.result = result;
    [self configureStep:step forFile:file];

    step.completionHandler = ^(ScriptInvocationStep *step) {
        [self didCompleteCompilationStep:step forFile:file];
        completionHandler();
    };

    NSLog(@"%@: %@", self.label, file.absolutePath);
    [step invoke];
}

- (void)configureStep:(ScriptInvocationStep *)step forFile:(LRProjectFile *)file {
    [self configureStep:step];
}

- (void)didCompleteCompilationStep:(ScriptInvocationStep *)step forFile:(LRProjectFile *)file {
}

- (void)invokeForProject:(Project *)project withModifiedFiles:(NSSet *)paths result:(LROperationResult *)result completionHandler:(dispatch_block_t)completionHandler {
}

@end
