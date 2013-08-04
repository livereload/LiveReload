
#import "ATChildTask.h"
#import "ATGlobals.h"



////////////////////////////////////////////////////////////////////////////////

static id ATPipeOrFileHandleForWriting(id task, NSPipe *pipe) {
    if ([task isKindOfClass:[NSTask class]])
        return pipe;
    else
        return pipe.fileHandleForWriting;
}

id ATLaunchUnixTaskAndCaptureOutput(NSURL *scriptURL, NSArray *arguments, ATLaunchUnixTaskAndCaptureOutputOptions options, ATLaunchUnixTaskAndCaptureOutputCompletionHandler handler) {
    NSError *error = nil;
    id task = ATCreateUserUnixTask(scriptURL, &error);
    if (!task) {
        handler(nil, nil, error);
        return nil;
    }

    BOOL merge = !!(options & ATLaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr);

    ATTaskOutputReader *outputReader = [[ATTaskOutputReader alloc] init];
    [task setStandardOutput:ATPipeOrFileHandleForWriting(task, outputReader.standardOutputPipe)];
    if (merge) {
        [task setStandardError:ATPipeOrFileHandleForWriting(task, outputReader.standardOutputPipe)];
        [outputReader.standardErrorPipe.fileHandleForWriting closeFile];
    } else {
        [task setStandardError:ATPipeOrFileHandleForWriting(task, outputReader.standardErrorPipe)];
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



////////////////////////////////////////////////////////////////////////////////
#pragma mark -

NSString *ATPlainUnixTaskErrorDomain = @"PlainUnixTask";


id ATCreateUserUnixTask(NSURL *scriptURL, NSError **error) {
    if (ATIsSandboxed()) {
        if (ATIsUserScriptsFolderSupported()) {
            return [[NSUserUnixTask alloc] initWithURL:scriptURL error:error];
        } else {
            if (error)
                *error = [NSError errorWithDomain:ATPlainUnixTaskErrorDomain code:PlainUnixTaskErrSandboxedTasksNotSupportedBefore10_8 userInfo:@{NSURLErrorKey:scriptURL}];
            return nil; // TODO
        }
    } else {
        return [[ATPlainUnixTask alloc] initWithURL:scriptURL error:error];
    }
}


@interface ATPlainUnixTask ()

@property(strong) NSURL *url;

@end


@implementation ATPlainUnixTask

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
            error = [NSError errorWithDomain:ATPlainUnixTaskErrorDomain code:PlainUnixTaskErrNonZeroExit userInfo:nil];
        }
        handler(error);
    };

    [task launch];
}

@end



////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation ATTaskOutputReader {
    NSPipe *_standardOutputPipe;
    NSPipe *_standardErrorPipe;

    NSMutableData *_standardOutputData;
    NSMutableData *_standardErrorData;

    BOOL _outputClosed;
    BOOL _errorClosed;
}

@synthesize standardOutputPipe=_standardOutputPipe;
@synthesize standardOutputData=_standardOutputData;
@synthesize standardErrorPipe=_standardErrorPipe;
@synthesize standardErrorData=_standardErrorData;

- (id)init {
    self = [super init];
    if (self) {
        _standardOutputPipe = [[NSPipe pipe] retain];
        _standardErrorPipe = [[NSPipe pipe] retain];

        _standardOutputData = [[NSMutableData alloc] init];
        _standardErrorData = [[NSMutableData alloc] init];
    }
    return self;
}

- (id)initWithTask:(id)task {
    self = [self init];
    if (self) {
        Class _NSUserUnixTask = NSClassFromString(@"NSUserUnixTask");
        if (_NSUserUnixTask && [task isKindOfClass:_NSUserUnixTask]) {
            [task setStandardOutput:self.standardOutputPipe.fileHandleForWriting];
            [task setStandardError:self.standardErrorPipe.fileHandleForWriting];
        } else {
            [task setStandardOutput:self.standardOutputPipe];
            [task setStandardError:self.standardErrorPipe];
        }
        [self startReading];
    }
    return self;
}

- (void)startReading {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(standardOutputNotification:) name:NSFileHandleDataAvailableNotification object:_standardOutputPipe.fileHandleForReading];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(standardErrorNotification:)  name:NSFileHandleDataAvailableNotification object:_standardErrorPipe.fileHandleForReading];

    [_standardOutputPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
    [_standardErrorPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_standardOutputPipe release];
    [_standardErrorPipe release];
    [_standardOutputData release];
    [_standardErrorData release];
    [super dealloc];
}

- (void)processPendingOutputData {
    NSData *availableData = [_standardOutputPipe.fileHandleForReading availableData];
    if ([availableData length] == 0) {
        _outputClosed = YES;
    } else {
        [_standardOutputData appendData:availableData];
    }
}

- (void)processPendingErrorData {
    NSData *availableData = [_standardErrorPipe.fileHandleForReading availableData];
    if ([availableData length] == 0) {
        _errorClosed = YES;
    } else {
        [_standardErrorData appendData:availableData];
    }
}

- (void)processPendingDataAndClosePipes {
    if (_standardOutputPipe) {
        [self processPendingOutputData];
        [_standardOutputPipe release], _standardOutputPipe = nil;
    }
    if (_standardErrorPipe) {
        [self processPendingErrorData];
        [_standardErrorPipe release], _standardErrorPipe = nil;
    }
}

-(void)standardOutputNotification:(NSNotification *)notification {
    [self processPendingOutputData];

    if (!_outputClosed)
        [_standardOutputPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
}

-(void)standardErrorNotification:(NSNotification *)notification {
    [self processPendingErrorData];

    if (!_errorClosed)
        [_standardErrorPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
}

- (NSString *)standardOutputText {
    [self processPendingDataAndClosePipes];
    return [[[NSString alloc] initWithData:_standardOutputData encoding:NSUTF8StringEncoding] autorelease];
}

- (NSString *)standardErrorText {
    [self processPendingDataAndClosePipes];
    return [[[NSString alloc] initWithData:_standardErrorData encoding:NSUTF8StringEncoding] autorelease];
}

- (NSString *)combinedOutputText {
    return [[self standardOutputText] stringByAppendingString:[self standardErrorText]];
}

@end
