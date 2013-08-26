
#import "AutoprefixerAction.h"

@implementation AutoprefixerAction

+ (NSString *)typeIdentifier {
    return @"autoprefixer";
}

- (NSString *)label {
    return NSLocalizedString(@"autoprefixer", nil);
}

- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler {
    
}

@end
