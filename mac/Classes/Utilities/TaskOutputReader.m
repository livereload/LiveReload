
#import "TaskOutputReader.h"


@implementation TaskOutputReader {
    NSPipe *_standardOutputPipe;
    NSPipe *_standardErrorPipe;

    NSMutableData *_standardOutputData;
    NSMutableData *_standardErrorData;
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

-(void)standardOutputNotification:(NSNotification *)notification {
    NSFileHandle *standardOutputFile = (NSFileHandle *)[notification object];

    NSData *availableData = [standardOutputFile availableData];
    if ([availableData length] == 0) {
//        outputClosed = YES;
        return;
    }

    [_standardOutputData appendData:availableData];
    [standardOutputFile waitForDataInBackgroundAndNotify];
}

-(void)standardErrorNotification:(NSNotification *)notification {
    NSFileHandle *standardErrorFile = (NSFileHandle *)[notification object];

    NSData *availableData = [standardErrorFile availableData];
    if ([availableData length] == 0) {
//        errorClosed = YES;
        return;
    }

    [_standardErrorData appendData:availableData];
    [standardErrorFile waitForDataInBackgroundAndNotify];
}

- (NSString *)standardOutputText {
    return [[[NSString alloc] initWithData:_standardOutputData encoding:NSUTF8StringEncoding] autorelease];
}

- (NSString *)standardErrorText {
    return [[[NSString alloc] initWithData:_standardErrorData encoding:NSUTF8StringEncoding] autorelease];
}

@end
