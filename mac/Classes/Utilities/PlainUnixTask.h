
#import <Foundation/Foundation.h>


// returns NSUserUnixTask or PlainUnixTask or nil
id CreateUserUnixTask(NSURL *scriptURL, NSError **error);


typedef enum {
    LaunchUnixTaskAndCaptureOutputOptionsNone = 0,
    LaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr = 0x01,
} LaunchUnixTaskAndCaptureOutputOptions;

typedef void (^LaunchUnixTaskAndCaptureOutputCompletionHandler)(NSString *outputText, NSString *stderrText, NSError *error);

id LaunchUnixTaskAndCaptureOutput(NSURL *scriptURL, NSArray *arguments, LaunchUnixTaskAndCaptureOutputOptions options, LaunchUnixTaskAndCaptureOutputCompletionHandler handler);


enum {
    kPlainUnixTaskErrNonZeroExit = 1,
};

// API compatible with NSUserUnixTask
@interface PlainUnixTask : NSObject

- (id)initWithURL:(NSURL *)url error:(NSError **)error;

@property(strong, readonly) NSURL *url;

// Standard I/O streams.  Setting them to nil (the default) will bind them to /dev/null.
// NSFileHandle or NSPipe
@property(strong) id standardInput;
@property(strong) id standardOutput;
@property(strong) id standardError;

// Execute the file with the given arguments.  "arguments" is an array of NSStrings.  The arguments do not undergo shell expansion, so you do not need to do special quoting, and shell variables are not resolved.
typedef void (^PlainUnixTaskCompletionHandler)(NSError *error);
- (void)executeWithArguments:(NSArray *)arguments completionHandler:(PlainUnixTaskCompletionHandler)handler;

@end
