@import Foundation;


extern NSString *const LRRuleEffectiveVersionDidChangeNotification;
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


extern NSString *const ActionKitErrorDomain;

typedef NS_ENUM(NSInteger, ActionKitErrorCode) {
    ActionKitErrorCodeNone,
    ActionKitErrorCodeInvalidManifest,
//    ActionKitErrorCodeJsonParsingError,
//    ActionKitErrorCodePluginNotReadable,
//    ActionKitErrorCodePluginNotExecutable,
//    ActionKitErrorCodePluginApiViolation,
//    ActionKitErrorCodeEditorPluginReturnedBrokenState,
    ActionKitErrorCodeNoMatchingVersion,
};
