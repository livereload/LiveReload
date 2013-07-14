
#import "PlainUnixTask.h"
#import "Errors.h"
#import "ATSandboxing.h"
#import "TaskOutputReader.h"


id CreateUserUnixTask(NSURL *scriptURL, NSError **error) {
    if (ATIsSandboxed()) {
        if (ATIsUserScriptsFolderSupported()) {
            return [[NSUserUnixTask alloc] initWithURL:scriptURL error:error];
        } else {
            if (error)
                *error = [NSError errorWithDomain:LRErrorDomain code:LRErrorSandboxedTasksNotSupportedBefore10_8 userInfo:@{NSURLErrorKey:scriptURL}];
            return nil; // TODO
        }
    } else {
        return [[PlainUnixTask alloc] initWithURL:scriptURL error:error];
    }
}

id LaunchUnixTaskAndCaptureOutput(NSURL *scriptURL, NSArray *arguments, LaunchUnixTaskAndCaptureOutputOptions options, LaunchUnixTaskAndCaptureOutputCompletionHandler handler) {
    NSError *error = nil;
    id task = CreateUserUnixTask(scriptURL, &error);
    if (!task) {
        handler(nil, nil, error);
        return nil;
    }

    BOOL merge = !!(options & LaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr);

    TaskOutputReader *outputReader = [[TaskOutputReader alloc] init];
    [task setStandardOutput:outputReader.standardOutputPipe.fileHandleForWriting];
    if (merge) {
        [task setStandardError:outputReader.standardOutputPipe.fileHandleForWriting];
        [outputReader.standardErrorPipe.fileHandleForWriting closeFile];
    } else {
        [task setStandardError:outputReader.standardErrorPipe.fileHandleForWriting];
    }
    [outputReader startReading];

    [task executeWithArguments:arguments completionHandler:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *outputText = outputReader.standardOutputText;
            NSString *stderrText = (merge ? outputText : outputReader.standardErrorText);
            handler(outputText, stderrText, error);
        });
    }];
    return task;
}



@interface PlainUnixTask ()

@property(strong) NSURL *url;

@end



@implementation PlainUnixTask

@synthesize url;
@synthesize standardInput;
@synthesize standardOutput;
@synthesize standardError;

- (id)initWithURL:(NSURL *)aUrl error:(NSError **)error {
    self = [super init];
    if (self) {
        self.url = aUrl;
        *error = nil;
    }
    return self;
}

- (void)executeWithArguments:(NSArray *)arguments completionHandler:(PlainUnixTaskCompletionHandler)handler {
    NSTask *task = [[NSTask alloc] init];

    [task setLaunchPath:[url path]];
    [task setArguments:arguments];

    // standard input is required, otherwise everything just hangs
    [task setStandardInput:self.standardInput ?: [NSFileHandle fileHandleWithNullDevice]];

    [task setStandardOutput:self.standardOutput ?: [NSFileHandle fileHandleWithNullDevice]];
    [task setStandardError:self.standardError ?: [NSFileHandle fileHandleWithNullDevice]];

    task.terminationHandler = ^(NSTask *task) {
        NSError *error = nil;
        if ([task terminationStatus] != 0) {
            error = [NSError errorWithDomain:@"PlainUnixTask" code:kPlainUnixTaskErrNonZeroExit userInfo:nil];
        }
        handler(error);
    };

    [task launch];
}

@end
