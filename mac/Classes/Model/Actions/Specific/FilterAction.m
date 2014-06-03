
#import "FilterAction.h"
#import "Project.h"
#import "LRProjectFile.h"
#import "ScriptInvocationStep.h"
#import "LRFileTargetResult.h"


@implementation FilterAction

- (NSString *)label {
    return self.type.name;
}

- (void)loadFromMemento:(NSDictionary *)memento {
    [super loadFromMemento:memento];

    NSString *inputFilter = self.type.manifest[@"input"];
    self.intrinsicInputPathSpec = [ATPathSpec pathSpecWithString:inputFilter syntaxOptions:ATPathSpecSyntaxFlavorExtended];
}

- (void)updateMemento:(NSMutableDictionary *)memento {
    [super updateMemento:memento];
    //    memento[@"output"] = self.outputFilterOption.memento;
}

- (void)configureStep:(ScriptInvocationStep *)step forFile:(LRProjectFile *)file {
    [super configureStep:step forFile:file];

    [step addFileValue:file forSubstitutionKey:@"src"];
}

- (void)didCompleteCompilationStep:(ScriptInvocationStep *)step forFile:(LRProjectFile *)file {
    LRProjectFile *outputFile = [step fileForKey:@"src"];
    [file.project hackhack_didFilterFile:outputFile];
}

- (void)compileFile:(LRProjectFile *)file inProject:(Project *)project result:(LROperationResult *)result completionHandler:(dispatch_block_t)completionHandler {
    if (![project hackhack_shouldFilterFile:file]) {
        completionHandler();
        return;
    }

    [super compileFile:file inProject:project result:result completionHandler:completionHandler];
}

- (BOOL)supportsFileTargets {
    return YES;
}

- (LRTargetResult *)fileTargetForRootFile:(LRProjectFile *)sourceFile {
    return [[LRFileTargetResult alloc] initWithAction:self sourceFile:sourceFile];
}


@end
