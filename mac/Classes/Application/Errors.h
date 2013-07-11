#import <Foundation/Foundation.h>

extern NSString *const LRErrorDomain;

enum {
    LRErrorSandboxedTasksNotSupportedBefore10_8,
    LRErrorPluginNotReadable,
    LRErrorPluginNotExecutable,
    LRErrorPluginApiViolation,
    LRErrorEditorPluginReturnedBrokenState,
};
