
#import "RubyInstance.h"

#import "RuntimeGlobals.h"
#import "PlainUnixTask.h"
#import "TaskOutputReader.h"
#import "NSData+Base64.h"
#import "ATSandboxing.h"

@implementation RubyInstance

- (void)doValidate {
    NSError *error;

    if (![[NSFileManager defaultManager] fileExistsAtPath:[self executablePath]]) {
        [self validationFailedWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Ruby executable file (bin/ruby) not found at %@", self.executablePath]}]];
        return;
    }

    PlainUnixTask *task = [[PlainUnixTask alloc] initWithURL:self.executableURL error:&error];
    if (!task) {
        [self validationFailedWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to create a task for validation"]}]];
        return;
    }

    TaskOutputReader *reader = [[TaskOutputReader alloc] initWithTask:task];
    [task executeWithArguments:@[@"--version"] completionHandler:^(NSError *error) {
        //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *components = [[reader.standardOutputText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *combinedOutput = reader.combinedOutputText;
            // reader can be released at this point

            if (error) {
                [self validationFailedWithError:error];
                return;
            }
            if ([[components objectAtIndex:0] isEqualToString:@"ruby"] && components.count > 1) {
                NSString *version = [components objectAtIndex:1];
                [self validationSucceededWithData:@{@"version": version}];
            } else {
                [self validationFailedWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to parse output of --version: '%@'", combinedOutput]}]];
            }
        });
    }];
}


#pragma mark - Presentation

- (NSString *)imageName {
    return @"RubyRuntime";
}

@end
