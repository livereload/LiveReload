
#import "ExternalEditor.h"
#import "Errors.h"
#import "NSString+ATProperURLEncoding.h"


static NSURL *ExpandFileURLTemplate(NSString *template, NSURL *fileURL, NSInteger line) {
    template = [template stringByReplacingOccurrencesOfString:@"((file))" withString:[[fileURL path] stringByEscapingURLComponent]];
    template = [template stringByReplacingOccurrencesOfString:@"((fileURL))" withString:[[fileURL absoluteString] stringByEscapingURLComponent]];
    template = [template stringByReplacingOccurrencesOfString:@"((line))" withString:[NSString stringWithFormat:@"%d", (int)line]];
    return [NSURL URLWithString:template];
}


@interface ExternalEditor ()
@end

@implementation ExternalEditor

@synthesize script = _script;
@synthesize magicURL1 = _magicURL1;
@synthesize magicURL2 = _magicURL2;
@synthesize magicURL3 = _magicURL3;

- (void)setAttributesDictionary:(NSDictionary *)attributes {
    [super setAttributesDictionary:attributes];

    self.defaultPriority = [attributes[@"default-priority"] integerValue]; // gives 0 for missing keys, which is exactly what we want
    self.script = attributes[@"script"];
    self.cocoaBundleId = attributes[@"cocoa-bundle-id"];
    self.magicURL1 = attributes[@"open-url-1"];
    self.magicURL2 = attributes[@"open-url-2"];
    self.magicURL3 = attributes[@"open-url-3"];
}

- (void)doUpdateStateInBackground {
    if (self.cocoaBundleId) {
        if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:self.cocoaBundleId] count] > 0) {
            [self updateState:EKEditorStateRunning error:nil];
            return;
        }
    }

    [self.script invokeWithArguments:@[@"--check"] options:ATLaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr completionHandler:^(NSString *outputText, NSString *stderrText, NSError *error) {
        NSLog(@"--check complete, error = %@, output = %@", [error localizedDescription], outputText);

        if (error) {
            [self updateState:EKEditorStateBroken error:error];
            return;
        }

        NSDictionary *output = LRParseKeyValueOutput(outputText);
        NSString *result = output[@"result"];
        if (!result) {
            [self updateState:EKEditorStateBroken error:[NSError errorWithDomain:LRErrorDomain code:LRErrorPluginApiViolation userInfo:@{NSLocalizedDescriptionKey: @"Editor --check must output 'result: running|found|broken|not-found'"}]];
            return;
        }

        NSString *message = output[@"message"];

        if ([result isEqualToString:@"found"]) {
            [self updateState:EKEditorStateFound error:nil];
        } else if ([result isEqualToString:@"running"])
            [self updateState:EKEditorStateRunning error:nil];
        else if ([result isEqualToString:@"broken"])
            [self updateState:EKEditorStateBroken error:[NSError errorWithDomain:LRErrorDomain code:LRErrorEditorPluginReturnedBrokenState userInfo:@{NSLocalizedDescriptionKey: message}]];
        else if ([result isEqualToString:@"not-found"])
            [self updateState:EKEditorStateNotFound error:nil];
        else
            [self updateState:EKEditorStateBroken error:[NSError errorWithDomain:LRErrorDomain code:LRErrorPluginApiViolation userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Editor --check returned unknown state '%@'", result]}]];
    }];
}

- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line {
    if (!self.script) {
        NSString *magicURLTemplate = nil;
        if (line >= 1)
            magicURLTemplate = self.magicURL2;
        else
            magicURLTemplate = self.magicURL1;

        if (magicURLTemplate) {
            NSURL *magicURL = ExpandFileURLTemplate(magicURLTemplate, [NSURL fileURLWithPath:file], line);
            if ([[NSWorkspace sharedWorkspace] openURLs:@[magicURL] withAppBundleIdentifier:self.cocoaBundleId options:0 additionalEventParamDescriptor:nil launchIdentifiers:NULL])
                return YES;
        }

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

    [self.script invokeWithArguments:arguments options:ATLaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr completionHandler:^(NSString *outputText, NSString *stderrText, NSError *error) {
        NSLog(@"Editor jump call complete, error = %@, output = %@", [error localizedDescription], outputText);
    }];
    return YES;
}

@end
