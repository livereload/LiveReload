//
//  NSTask+OneLineTasksWithOutput.m
//  OpenFileKiller
//
//  Created by Matt Gallagher on 4/05/09.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "NSTask+OneLineTasksWithOutput.h"

@interface TaskOutputReader :NSObject
{
    NSMutableData *standardOutput;
    NSMutableData *standardError;
    BOOL taskComplete;
    BOOL outputClosed;
    BOOL errorClosed;
    NSTask *task;
}
@end

@implementation TaskOutputReader

//
// initWithTask:
//
// Sets the object as an observer for notifications from the task or its
// file handles.
//
// Parameters:
//    aTask - the NSTask object to observe.
//
// returns the initialized output reader
//
- (id)initWithTask:(NSTask *)aTask
{
    self = [super init];
    if (self != nil)
    {
        task = [aTask retain];
        standardOutput = [[NSMutableData alloc] init];
        standardError = [[NSMutableData alloc] init];

        NSFileHandle *standardOutputFile = [[aTask standardOutput] fileHandleForReading];
        NSFileHandle *standardErrorFile = [[aTask standardError] fileHandleForReading];

        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(standardOutNotification:)
            name:NSFileHandleDataAvailableNotification
            object:standardOutputFile];
        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(standardErrorNotification:)
            name:NSFileHandleDataAvailableNotification
            object:standardErrorFile];
        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(terminatedNotification:)
            name:NSTaskDidTerminateNotification
            object:aTask];

        [standardOutputFile waitForDataInBackgroundAndNotify];
        [standardErrorFile waitForDataInBackgroundAndNotify];
    }
    return self;
}

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [standardOutput release];
    [standardError release];
    [task release];
    [super dealloc];
}

//
// standardOutputData
//
// Accessor for the data object
//
// returns the object.
//
- (NSData *)standardOutputData
{
    return standardOutput;
}

//
// standardErrorData
//
// Accessor for the data object
//
// returns the object.
//
- (NSData *)standardErrorData
{
    return standardError;
}

//
// standardOutNotification:
//
// Reads standard out into the standardOutput data object.
//
// Parameters:
//    notification - the notification containing the NSFileHandle to read
//
-(void)standardOutNotification: (NSNotification *) notification
{
    NSFileHandle *standardOutFile = (NSFileHandle *)[notification object];

    NSData *availableData = [standardOutFile availableData];
    if ([availableData length] == 0)
    {
        outputClosed = YES;
        return;
    }

    [standardOutput appendData:availableData];
    [standardOutFile waitForDataInBackgroundAndNotify];
}

//
// standardErrorNotification:
//
// Reads standard error into the standardError data object.
//
// Parameters:
//    notification - the notification containing the NSFileHandle to read
//
-(void)standardErrorNotification: (NSNotification *) notification
{
    NSFileHandle *standardErrorFile = (NSFileHandle *)[notification object];

    NSData *availableData = [standardErrorFile availableData];
    if ([availableData length] == 0)
    {
        errorClosed = YES;
        return;
    }

    [standardError appendData:availableData];
    [standardErrorFile waitForDataInBackgroundAndNotify];
}

//
// terminatedNotification:
//
// Sets the taskComplete flag when a terminated notification is received.
//
// Parameters:
//    notification - the notification
//
- (void)terminatedNotification: (NSNotification *)notification
{
    taskComplete = YES;
}

//
// launchTaskAndRunSynchronous
//
// Runs the current event loop until the terminated notification is received
//
- (void)launchTaskAndRunSynchronous
{
    [task launch];

    BOOL isRunning = YES;
    while (isRunning && (!taskComplete || !outputClosed || !errorClosed))
    {
        isRunning =
            [[NSRunLoop currentRunLoop]
                runMode:NSDefaultRunLoopMode
                beforeDate:[NSDate distantFuture]];
    }
}

//
// launchTaskAndRunSynchronous
//
// Runs the current event loop until the terminated notification is received
//
- (void)launchTaskAndRunAsynchronousForObject:(id)receiver selector:(SEL)selector
{
    [task launch];

    BOOL isRunning = YES;
    while (isRunning && (!taskComplete || !outputClosed || !errorClosed))
    {
        isRunning =
            [[NSRunLoop currentRunLoop]
                runMode:NSDefaultRunLoopMode
                beforeDate:[NSDate distantFuture]];
    }
}

@end

@implementation NSTask (OneLineTasksWithOutput)

//
// stringByLaunchingPath:withArguments:error:
//
// Executes a process and returns the standard output as an NSString
//
// Parameters:
//    processPath - the path to the executable
//    arguments - arguments to pass to the executable
//    error - an NSError pointer or nil
//
// Returns the standard out from the process an an NSString (if the NSTask
//    completes successfully), nil otherwise.
//
// Error handling notes:
//
// If the NSTask throws an exception, it will be automatically caught and
// the "error" object will have the code kNSTaskLaunchFailed and the
// localizedDescription will be the -[NSException reason] from the thrown
// exception. The return value will be nil in this case.
//
// If the NSTask is successfully run but outputs on standard error, the
// localizedDescription of the NSError will be set to the string output to
// standard error (the output on standard out will still be returned as a
// string). The error code will be kNSTaskProcessOutputError in this case.
//
+ (NSString *)stringByLaunchingPath:(NSString *)processPath
    withArguments:(NSArray *)arguments
    error:(NSError **)error
{
    NSTask *task = [[[NSTask alloc] init] autorelease];

    [task setLaunchPath:processPath];
    [task setArguments:arguments];
    [task setStandardOutput:[NSPipe pipe]];
    [task setStandardError:[NSPipe pipe]];

    TaskOutputReader *outputReader = [[TaskOutputReader alloc] initWithTask:task];

    NSString *outputString = nil;
    NSString *errorString = nil;
    @try
    {
        [outputReader launchTaskAndRunSynchronous];

        outputString =
            [[[NSString alloc]
                initWithData:[outputReader standardOutputData]
                encoding:NSUTF8StringEncoding]
            autorelease];
        errorString =
            [[[NSString alloc]
                initWithData:[outputReader standardErrorData]
                encoding:NSUTF8StringEncoding]
            autorelease];
    }
    @catch (NSException *exception)
    {
        *error =
            [NSError
                errorWithDomain:@"com.apple.NSTask.OneLineTasksWithOutput"
                code:kNSTaskLaunchFailed
                userInfo:
                    [NSDictionary
                        dictionaryWithObject:[exception reason]
                        forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
    @finally
    {
        [outputReader release];
    }

    if (error)
    {
        if ([task terminationStatus] != 0)
        {
            *error =
                [NSError
                    errorWithDomain:@"com.apple.NSTask.OneLineTasksWithOutput"
                    code:kNSTaskProcessOutputError
                    userInfo:
                        [NSDictionary
                            dictionaryWithObject:errorString
                            forKey:@"standardError"]];
        }
        else
        {
            *error = nil;
        }
    }
    return [outputString stringByAppendingString:errorString];
}

#if 0
//
// stringByLaunchingPath:withArguments:error:
//
// Executes a process with specified authorization and returns the standard
// output as an NSString.
//
// Parameters:
//    processPath - the path to the executable
//    arguments - arguments to pass to the executable
//      authorization - an SFAuthorization object specifying the privileges
//    error - an NSError pointer or nil
//
// Returns the standard out from the process an an NSString (if the
//  AuthorizationExecuteWithPrivileges completes successfully), nil otherwise.
//
// Error handling notes:
//
// If any error is returned from AuthorizationExecuteWithPrivileges, the error
// object will have its code set to the OSErr that it returns an nil will be
// returned from the method.
//
+ (NSString *)stringByLaunchingPath:(NSString *)processPath
    withArguments:(NSArray *)arguments
    authorization:(SFAuthorization *)authorization
    error:(NSError **)error
{
    //
    // Create a nil terminated C array of pointers to UTF8Strings for use as the
    // argv array.
    //
    const char **argv = (const char **)malloc(sizeof(char *) * [arguments count] + 1);
    NSInteger argvIndex = 0;
    for (NSString *string in arguments)
    {
        argv[argvIndex] = [string UTF8String];
        argvIndex++;
    }
    argv[argvIndex] = nil;

    //
    // Perform the process invocation
    //
    FILE *processOutput;
    OSErr processError =
        AuthorizationExecuteWithPrivileges(
            [authorization authorizationRef],
            [processPath UTF8String],
            kAuthorizationFlagDefaults,
            (char *const *)argv,
            &processOutput);
    free(argv);

    //
    // Handle errors
    //
    if (processError != errAuthorizationSuccess)
    {
        if (error)
        {
            *error =
                [NSError
                    errorWithDomain:@"com.apple.NSTask.OneLineTasksWithOutput"
                    code:processError
                    userInfo:nil];
        }
        return nil;
    }
    if (error)
    {
        *error = nil;
    }

    //
    // Read the output from the FILE pipe up to EOF (or other error).
    //
#define READ_BUFFER_SIZE 64
    char readBuffer[READ_BUFFER_SIZE];
    NSMutableString *processOutputString = [NSMutableString string];
    size_t charsRead;
    while ((charsRead = fread(readBuffer, 1, READ_BUFFER_SIZE, processOutput)) != 0)
    {
        NSString *bufferString =
            [[NSString alloc]
                initWithBytes:readBuffer
                length:charsRead
                encoding:NSUTF8StringEncoding];
        [processOutputString appendString:bufferString];
        [bufferString release];
    }
    fclose(processOutput);

    return processOutputString;
}
#endif

@end
