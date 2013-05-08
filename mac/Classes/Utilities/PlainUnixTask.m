
#import "PlainUnixTask.h"



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
    [task setStandardInput:self.standardInput ?: [NSPipe pipe]];

    [task setStandardOutput:self.standardOutput];
    [task setStandardError:self.standardError];

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
