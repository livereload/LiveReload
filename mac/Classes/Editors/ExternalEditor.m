
#import "ExternalEditor.h"
#import "Errors.h"


@interface ExternalEditor ()
@end

@implementation ExternalEditor

@synthesize script = _script;
@synthesize cocoaBundleId = _cocoaBundleId;

- (void)setAttributesDictionary:(NSDictionary *)attributes {
    [super setAttributesDictionary:attributes];

    self.defaultPriority = [attributes[@"default-priority"] integerValue]; // gives 0 for missing keys, which is exactly what we want
    self.script = attributes[@"script"];
    self.cocoaBundleId = attributes[@"cocoa-bundle-id"];
}

- (void)doUpdateStateInBackground {
    if (self.cocoaBundleId) {
        if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:self.cocoaBundleId] count] > 0) {
            [self updateState:EditorStateRunning error:nil];
            return;
        }
    }

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
    if (!self.script) {
        if (self.cocoaBundleId) {
            NSURL *fileURL = [NSURL fileURLWithPath:file];
            if ([[NSWorkspace sharedWorkspace] openURLs:@[fileURL] withAppBundleIdentifier:self.cocoaBundleId options:0 additionalEventParamDescriptor:nil launchIdentifiers:NULL])
                return YES;
        }
        return NO;
    }

    NSArray *arguments = @[file];
    if (line >= 0)
        arguments = [arguments arrayByAddingObject:[NSString stringWithFormat:@"%d", (int)line]];

    [self.script invokeWithArguments:arguments options:LaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr completionHandler:^(NSString *outputText, NSString *stderrText, NSError *error) {
        NSLog(@"Editor jump call complete, error = %@, output = %@", [error localizedDescription], outputText);
    }];
    return YES;
}

@end
