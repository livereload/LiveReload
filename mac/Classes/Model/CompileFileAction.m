
#import "CompileFileAction.h"
#import "ScriptInvocationStep.h"
//#import "Project.h"
//#import "Plugin.h"
#import "LRFile2.h"
#import "LRFile.h"


@implementation CompileFileAction

- (NSString *)label {
    return self.type.name;
}

- (void)loadFromMemento:(NSDictionary *)memento {
    [super loadFromMemento:memento];
    self.compilerName = memento[@"compiler"];
//    self.intrinsicInputPathSpec = [ATPathSpec pathSpecWithString:@"*.css" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    self.outputFilterOption = [FilterOption filterOptionWithMemento:(memento[@"output"] ?: @"subdir:.")];
}

- (void)updateMemento:(NSMutableDictionary *)memento {
    [super updateMemento:memento];

    memento[@"output"] = self.outputFilterOption.memento;
}

- (void)configureStep:(ScriptInvocationStep *)step forFile:(LRFile2 *)file {
    [super configureStep:step forFile:file];

    [step addValue:@[] forSubstitutionKey:@"additional"]; // TODO
    [step addFileValue:file forSubstitutionKey:@"src"];

    // we cheat a little, reusing the impl from LRFile (TODO should extract the common helpers)
    LRFile *fakeFile = [[LRFile alloc] initWithFile:file.relativePath memento:nil];
    fakeFile.destinationDirectory = self.outputFilterOption.subfolder;
    fakeFile.destinationNameMask = self.type.options[@"output"];
    NSString *destinationRelativePath = fakeFile.destinationPath;

    LRFile2 *destinationFile = [LRFile2 fileWithRelativePath:destinationRelativePath project:step.project];
    [step addFileValue:destinationFile forSubstitutionKey:@"dst"];
}

@end
