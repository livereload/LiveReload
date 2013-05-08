
#import <Foundation/Foundation.h>

enum {
    kPlainUnixTaskErrNonZeroExit = 1,
};

// API compatible with NSUserUnixTask
@interface PlainUnixTask : NSObject

- (id)initWithURL:(NSURL *)url error:(NSError **)error;

@property(strong, readonly) NSURL *url;

// Standard I/O streams.  Setting them to nil (the default) will bind them to /dev/null.
@property(strong) NSFileHandle *standardInput;
@property(strong) NSFileHandle *standardOutput;
@property(strong) NSFileHandle *standardError;

// Execute the file with the given arguments.  "arguments" is an array of NSStrings.  The arguments do not undergo shell expansion, so you do not need to do special quoting, and shell variables are not resolved.
typedef void (^PlainUnixTaskCompletionHandler)(NSError *error);
- (void)executeWithArguments:(NSArray *)arguments completionHandler:(PlainUnixTaskCompletionHandler)handler;

@end
