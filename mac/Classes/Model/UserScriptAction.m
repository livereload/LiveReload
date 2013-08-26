
#import "UserScriptAction.h"


@implementation UserScriptAction

+ (NSString *)typeIdentifier {
    return @"script";
}

+ (ActionKind)kind {
    return ActionKindPostproc;
}

- (NSString *)label {
    return [NSString stringWithFormat:NSLocalizedString(@"Run %@", nil), self.scriptName];
}

+ (NSSet *)keyPathsForValuesAffectingLabel {
    return [NSSet setWithObject:@"scriptName"];
}

- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler {
    [self.script invokeForProjectAtPath:projectPath withModifiedFiles:paths completionHandler:completionHandler];
}

- (UserScript *)script {
    if (_scriptName.length == 0)
        return nil;

    NSArray *userScripts = [UserScriptManager sharedUserScriptManager].userScripts;
    for (UserScript *userScript in userScripts) {
        if ([userScript.uniqueName isEqualToString:_scriptName])
            return userScript;
    }

    return [[MissingUserScript alloc] initWithName:_scriptName];
}

+ (NSSet *)keyPathsForValuesAffectingScript {
    return [NSSet setWithObject:@"scriptName"];
}

- (BOOL)isNonEmpty {
    return self.scriptName.length > 0 && self.script.exists;
}

+ (NSSet *)keyPathsForValuesAffectingNonEmpty {
    return [NSSet setWithObject:@"scriptName"];
}

- (void)loadFromMemento:(NSDictionary *)memento {
    [super loadFromMemento:memento];
    self.scriptName = memento[@"script"] ?: @"";
}

- (void)updateMemento:(NSMutableDictionary *)memento {
    [super updateMemento:memento];
    memento[@"script"] = self.scriptName;
}

@end
