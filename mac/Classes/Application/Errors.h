#import <Foundation/Foundation.h>

extern NSString *const LRErrorDomain;

enum {
    LRErrorSandboxedTasksNotSupportedBefore10_8,
    LRErrorJsonParsingError,
    LRErrorPluginNotReadable,
    LRErrorPluginNotExecutable,
    LRErrorPluginApiViolation,
    LRErrorEditorPluginReturnedBrokenState,
};

#define return_error(returnValue, outError, error)  do { \
        if (outError) *outError = error; \
        return nil; \
    } while(0)
