
#import "CompileFileAction.h"
#import "ScriptInvocationStep.h"
#import "Project.h"
//#import "Plugin.h"
#import "LRFile2.h"
#import "LRFile.h"
#import "LRPathProcessing.h"


@implementation CompileFileAction

- (NSString *)label {
    return self.type.name;
}

- (void)loadFromMemento:(NSDictionary *)memento {
    [super loadFromMemento:memento];
    self.compilerName = memento[@"compiler"];
//    self.intrinsicInputPathSpec = [ATPathSpec pathSpecWithString:@"*.css" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    self.outputFilterOption = [FilterOption filterOptionWithMemento:(memento[@"output"] ?: @"subdir:.")];

    NSString *inputFilter = self.type.manifest[@"input"];
    self.intrinsicInputPathSpec = [ATPathSpec pathSpecWithString:inputFilter syntaxOptions:ATPathSpecSyntaxFlavorExtended];
}

- (void)updateMemento:(NSMutableDictionary *)memento {
    [super updateMemento:memento];

    memento[@"output"] = self.outputFilterOption.memento;
}

- (void)configureStep:(ScriptInvocationStep *)step forFile:(LRFile2 *)file {
    [super configureStep:step forFile:file];

    [step addFileValue:file forSubstitutionKey:@"src"];

    NSString *destinationName = LRDeriveDestinationFileName([file.relativePath lastPathComponent], self.type.manifest[@"output"], self.intrinsicInputPathSpec);

    NSString *destinationRelativePath = nil;
    if (self.outputFilterOption.subfolder)
        destinationRelativePath = [self.outputFilterOption.subfolder stringByAppendingPathComponent:destinationName];

    LRFile2 *destinationFile = [LRFile2 fileWithRelativePath:destinationRelativePath project:step.project];
    [step addFileValue:destinationFile forSubstitutionKey:@"dst"];
}

- (void)didCompleteCompilationStep:(ScriptInvocationStep *)step forFile:(LRFile2 *)file {
    LRFile2 *outputFile = [step fileForKey:@"dst"];
    [file.project hackhack_didWriteCompiledFile:outputFile];
}

@end
