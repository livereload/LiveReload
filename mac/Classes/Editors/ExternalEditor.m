
#import "ExternalEditor.h"
#import "Errors.h"


@interface ExternalEditor ()
@end

@implementation ExternalEditor

@synthesize script = _script;

- (id)initWithScript:(SingleFilePlugin*)aScript {
    self = [super init];
    if (self) {
        _script = [aScript retain];
    }
    return self;
}

- (NSString *)displayName {
    return self.script.properties[@"editor-name"];
}

- (void)doUpdateStateInBackground {
    [self.script invokeWithArguments:@[@"--check"] options:LaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr completionHandler:^(NSString *outputText, NSString *stderrText, NSError *error) {
        NSLog(@"--check complete, error = %@, output = %@", [error localizedDescription], outputText);

        if (error) {
            [self updateState:EditorStateBroken error:error];
            return;
        }

        NSDictionary *output = LRParseKeyValueOutput(outputText);
        NSString *result = output[@"result"];
        if (!result) {
            [self updateState:EditorStateBroken error:[NSError errorWithDomain:LRErrorDomain code:LRErrorPluginApiViolation userInfo:@{NSLocalizedDescriptionKey: @"Editor --check must output 'result: running|found|broken|not-found'"}]];
            return;
        }

        NSString *message = output[@"message"];

        if ([result isEqualToString:@"found"]) {
            NSString *appId = self.script.properties[@"editor-app-id"];
            if (appId) {
                if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:appId] count] > 0) {
                    [self updateState:EditorStateRunning error:nil];
                    return;
                }
            }
            [self updateState:EditorStateFound error:nil];
        } else if ([result isEqualToString:@"running"])
            [self updateState:EditorStateRunning error:nil];
        else if ([result isEqualToString:@"broken"])
            [self updateState:EditorStateBroken error:[NSError errorWithDomain:LRErrorDomain code:LRErrorEditorPluginReturnedBrokenState userInfo:@{NSLocalizedDescriptionKey: message}]];
        else if ([result isEqualToString:@"not-found"])
            [self updateState:EditorStateNotFound error:nil];
        else
            [self updateState:EditorStateBroken error:[NSError errorWithDomain:LRErrorDomain code:LRErrorPluginApiViolation userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Editor --check returned unknown state '%@'", result]}]];
    }];
}

@end
