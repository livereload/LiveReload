
#import "AutoprefixerAction.h"
#import "Project.h"
#import "LRFile2.h"


@implementation AutoprefixerAction

- (NSString *)label {
    return NSLocalizedString(@"autoprefixer", nil);
}

- (void)loadFromMemento:(NSDictionary *)memento {
    [super loadFromMemento:memento];
    self.intrinsicInputPathSpec = [ATPathSpec pathSpecWithString:@"*.css" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
}

- (void)compileFile:(LRFile2 *)file inProject:(Project *)project completionHandler:(UserScriptCompletionHandler)completionHandler {
    NSLog(@"Applying autoprefixer to %@/%@", project.path, file.relativePath);
    completionHandler(YES, nil, nil);
}

- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler {
}

@end
