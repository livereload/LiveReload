
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
    LRActionManifest *manifest = self.effectiveVersion.manifest;
    step.commandLine = manifest.commandLineSpec;
    step.manifest = @{@"errors": manifest.errorSpecs};
    [step addValue:self.type.plugin.path forSubstitutionKey:@"plugin"];

    for (LRPackage *package in self.effectiveVersion.packageSet.packages) {
        [step addValue:package.sourceFolderURL.path forSubstitutionKey:package.identifier];
        [step addValue:package.version.description forSubstitutionKey:[NSString stringWithFormat:@"%@.ver", package.identifier]];
    }

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
