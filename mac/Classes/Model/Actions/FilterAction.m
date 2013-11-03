
#import "FilterAction.h"
#import "Project.h"
#import "LRFile2.h"
#import "ScriptInvocationStep.h"


@implementation FilterAction

- (NSString *)label {
    return self.type.name;
}

- (void)loadFromMemento:(NSDictionary *)memento {
    [super loadFromMemento:memento];

    NSString *inputFilter = self.type.options[@"input"];
    self.intrinsicInputPathSpec = [ATPathSpec pathSpecWithString:inputFilter syntaxOptions:ATPathSpecSyntaxFlavorExtended];
}

- (void)updateMemento:(NSMutableDictionary *)memento {
    [super updateMemento:memento];
    //    memento[@"output"] = self.outputFilterOption.memento;
}

- (void)configureStep:(ScriptInvocationStep *)step forFile:(LRFile2 *)file {
    [super configureStep:step forFile:file];

    [step addFileValue:file forSubstitutionKey:@"src"];
}

- (void)didCompleteCompilationStep:(ScriptInvocationStep *)step forFile:(LRFile2 *)file {
    LRFile2 *outputFile = [step fileForKey:@"src"];
    [file.project hackhack_didFilterFile:outputFile];
}

- (void)compileFile:(LRFile2 *)file inProject:(Project *)project completionHandler:(UserScriptCompletionHandler)completionHandler {
    if (![project hackhack_shouldFilterFile:file]) {
        completionHandler(NO, nil, nil);
        return;
    }

    [super compileFile:file inProject:project completionHandler:completionHandler];
}


@end
