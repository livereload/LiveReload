
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
        [self updateDerivedProperties];
    }
    return self;
}

- (NSString *)identifier {
    return self.script.properties[@"editor-id"];
}

- (NSString *)displayName {
    return self.script.properties[@"editor-name"];
}

- (void)updateScript:(SingleFilePlugin *)script {
    if ([_script updateProperties:script.properties]) {
        [self updateDerivedProperties];
        [self updateStateSoon];
    }
}

- (void)updateDerivedProperties {
    // gives 0 for missing keys, which is exactly what we want
    self.defaultPriority = [self.script.properties[@"editor-default-priotity"] integerValue];
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

- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line {
    NSArray *arguments = @[file];
    if (line >= 0)
        arguments = [arguments arrayByAddingObject:[NSString stringWithFormat:@"%d", (int)line]];

    [self.script invokeWithArguments:arguments options:LaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr completionHandler:^(NSString *outputText, NSString *stderrText, NSError *error) {
        NSLog(@"Editor jump call complete, error = %@, output = %@", [error localizedDescription], outputText);
    }];
    return YES;
}

@end
