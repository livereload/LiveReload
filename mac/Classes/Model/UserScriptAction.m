
#import "UserScriptAction.h"


@implementation UserScriptAction

+ (NSString *)typeIdentifier {
    return @"script";
}

- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler {
    abort();
}

@end
