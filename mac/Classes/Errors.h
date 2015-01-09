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
