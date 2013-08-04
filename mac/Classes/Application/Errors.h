#import <Foundation/Foundation.h>

extern NSString *const LRErrorDomain;

enum {
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
