@import Foundation;


extern NSString *const LRActionPrimaryEffectiveVersionDidChangeNotification;
extern NSString *const LRBuildDidFinishNotification;


typedef NS_ENUM(NSInteger, ActionKind) {
    ActionKindUnknown = 0,
    ActionKindCompiler,
    ActionKindFilter,
    ActionKindPostproc,
};

ActionKind LRActionKindFromString(NSString *kindString);
NSString *LRStringFromActionKind(ActionKind kind);
NSArray *LRValidActionKindStrings();


typedef NS_ENUM(NSInteger, LRMessageSeverity) {
    LRMessageSeverityError = 1,
    LRMessageSeverityWarning,
};


extern NSString *const LRActionKitErrorDomain;

typedef NS_ENUM(NSInteger, LRActionKitErrorCode) {
    LRActionKitErrorCodeNone,
    LRActionKitErrorCodeInvalidManifest,
//    LRActionKitErrorCodeJsonParsingError,
//    LRActionKitErrorCodePluginNotReadable,
//    LRActionKitErrorCodePluginNotExecutable,
//    LRActionKitErrorCodePluginApiViolation,
//    LRActionKitErrorCodeEditorPluginReturnedBrokenState,
//    LRActionKitErrorCodeNoMatchingVersion,
};
