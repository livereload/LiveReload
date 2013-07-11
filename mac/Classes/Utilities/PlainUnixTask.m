
#import "PlainUnixTask.h"
#import "Errors.h"
#import "ATSandboxing.h"


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
