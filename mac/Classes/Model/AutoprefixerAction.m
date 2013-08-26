
#import "AutoprefixerAction.h"
#import "Project.h"
#import "LRFile2.h"


@implementation AutoprefixerAction

+ (NSString *)typeIdentifier {
    return @"autoprefixer";
}

+ (ActionKind)kind {
    return ActionKindFilter;
}

- (NSString *)label {
    return NSLocalizedString(@"autoprefixer", nil);
}

- (void)compileFile:(LRFile2 *)file inProject:(Project *)project completionHandler:(UserScriptCompletionHandler)completionHandler {
    NSLog(@"Applying autoprefixer to %@/%@", project.path, file.relativePath);
    completionHandler(YES, nil, nil);
}

- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler {
}

@end
