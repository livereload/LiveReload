
#import "TaskOutputReader.h"


@implementation TaskOutputReader {
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
