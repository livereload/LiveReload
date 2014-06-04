
#import "UserScriptAction.h"
#import "Project.h"
#import "LRProjectTargetResult.h"


@implementation UserScriptAction

- (NSString *)label {
    return [NSString stringWithFormat:NSLocalizedString(@"Run %@", nil), self.scriptName];
}

+ (NSSet *)keyPathsForValuesAffectingLabel {
    return [NSSet setWithObject:@"scriptName"];
}

- (void)invokeForProject:(Project *)project withModifiedFiles:(NSArray *)files result:(LROperationResult *)result completionHandler:(dispatch_block_t)completionHandler {
    [self.script invokeForProjectAtPath:project.rootURL.path withModifiedFiles:[NSSet setWithArray:[files valueForKeyPath:@"relativePath"]] result:result completionHandler:completionHandler];
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

- (LRTarget *)targetForModifiedFiles:(NSArray *)files {
    if ([self inputPathSpecMatchesFiles:files]) {
        return [[LRProjectTargetResult alloc] initWithAction:self modifiedFiles:files];
    } else {
        return nil;
    }
}

@end
