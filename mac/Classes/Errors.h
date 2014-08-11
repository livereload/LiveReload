#import <Foundation/Foundation.h>

extern NSString *const LRErrorDomain;

enum {
    LRErrorJsonParsingError,
    LRErrorPluginNotReadable,
    LRErrorPluginNotExecutable,
    LRErrorPluginApiViolation,
    LRErrorEditorPluginReturnedBrokenState,
    LRErrorNoMatchingVersion,
};

#define return_error(returnValue, outError, error)  do { \
        if (outError) *outError = error; \
        return nil; \
    } while(0)
