
#import "RubyInstance.h"

#import "RuntimeGlobals.h"
#import "PlainUnixTask.h"
#import "TaskOutputReader.h"
#import "NSData+Base64.h"

@implementation RubyInstance

- (void)resolveBookmark {
    NSString *bookmarkString = self.memento[@"bookmark"];
    if (bookmarkString) {
        NSData *bookmark = [NSData dataFromBase64String:bookmarkString];

        BOOL stale = NO;
        NSError *error;
        NSURL *url = [NSURL URLByResolvingBookmarkData:bookmark options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&stale error:&error];
        if (url) {
            self.executablePath = [[url path] stringByAppendingPathComponent:@"bin/ruby"];
            self.memento[@"executablePath"] = self.executablePath;

            if (stale) {
                bookmarkString = [[url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope|NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess includingResourceValuesForKeys:nil relativeToURL:nil error:&error] base64EncodedString];
                if (bookmarkString) {
                    self.memento[@"bookmark"] = bookmarkString;
                }
            }

            [url startAccessingSecurityScopedResource];
        }
    }
}

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

@end
