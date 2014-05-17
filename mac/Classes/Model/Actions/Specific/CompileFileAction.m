
#import "CompileFileAction.h"
#import "ScriptInvocationStep.h"
#import "Project.h"
//#import "Plugin.h"
#import "LRProjectFile.h"
#import "LRPathProcessing.h"
#import "LRFileTargetResult.h"


@implementation CompileFileAction

- (NSString *)label {
    return self.type.name;
}

- (void)loadFromMemento:(NSDictionary *)memento {
    [super loadFromMemento:memento];
    self.compilerName = memento[@"compiler"];
//    self.intrinsicInputPathSpec = [ATPathSpec pathSpecWithString:@"*.css" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    _outputFilterOption = [FilterOption filterOptionWithMemento:(memento[@"output"] ?: @"subdir:.")];

    NSString *inputFilter = self.type.manifest[@"input"];
    self.intrinsicInputPathSpec = [ATPathSpec pathSpecWithString:inputFilter syntaxOptions:ATPathSpecSyntaxFlavorExtended];
}

- (void)setOutputFilterOption:(FilterOption *)outputFilterOption {
    if (_outputFilterOption != outputFilterOption) {
        _outputFilterOption = outputFilterOption;
        [self didChange];
    }
}

- (void)updateMemento:(NSMutableDictionary *)memento {
    [super updateMemento:memento];

    memento[@"output"] = self.outputFilterOption.memento;
}

- (LRProjectFile *)destinationFileForSourceFile:(LRProjectFile *)file inProject:(Project *)project {
    NSString *destinationName = LRDeriveDestinationFileName([file.relativePath lastPathComponent], self.type.manifest[@"output"], self.intrinsicInputPathSpec);

    BOOL outputMappingIsRecursive = YES; // TODO: make this conditional
    if (outputMappingIsRecursive) {
        NSUInteger folderComponentCount = self.inputFilterOption.folderComponentCount;
        if (folderComponentCount > 0) {
            NSArray *components = [[file.relativePath stringByDeletingLastPathComponent] pathComponents];
            if (components.count > folderComponentCount) {
                destinationName = [[[components subarrayWithRange:NSMakeRange(folderComponentCount, components.count - folderComponentCount)] componentsJoinedByString:@"/"] stringByAppendingPathComponent:destinationName];
            }
        }
    }

    NSString *destinationRelativePath = nil;
    if (self.outputFilterOption.subfolder)
        destinationRelativePath = [self.outputFilterOption.subfolder stringByAppendingPathComponent:destinationName];

    return [LRProjectFile fileWithRelativePath:destinationRelativePath project:project];
}

- (void)handleDeletionOfFile:(LRProjectFile *)file inProject:(Project *)project {
    LRProjectFile *destinationFile = [self destinationFileForSourceFile:file inProject:project];
    if (![destinationFile.absoluteURL isEqual:file.absoluteURL] && destinationFile.exists) {
        [[NSFileManager defaultManager] removeItemAtURL:destinationFile.absoluteURL error:NULL];
    }
}

- (void)configureStep:(ScriptInvocationStep *)step forFile:(LRProjectFile *)file {
    [super configureStep:step forFile:file];

    [step addFileValue:file forSubstitutionKey:@"src"];

    LRProjectFile *destinationFile = [self destinationFileForSourceFile:file inProject:step.project];

    NSURL *destinationFolderURL = [destinationFile.absoluteURL URLByDeletingLastPathComponent];
    if (![destinationFolderURL checkResourceIsReachableAndReturnError:NULL]) {
        [[NSFileManager defaultManager] createDirectoryAtURL:destinationFolderURL withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    [step addFileValue:destinationFile forSubstitutionKey:@"dst"];
}

- (void)didCompleteCompilationStep:(ScriptInvocationStep *)step forFile:(LRProjectFile *)file {
    LRProjectFile *outputFile = [step fileForKey:@"dst"];
    [file.project hackhack_didWriteCompiledFile:outputFile];
}

- (BOOL)supportsFileTargets {
    return YES;
}

- (LRTargetResult *)fileTargetForRootFile:(LRProjectFile *)sourceFile {
    return [[LRFileTargetResult alloc] initWithAction:self sourceFile:sourceFile];
}

@end
