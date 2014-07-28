@import Foundation;

extern NSString *const LRActionPrimaryEffectiveVersionDidChangeNotification;
extern NSString *const LRBuildDidFinishNotification;

typedef NS_ENUM(NSInteger, ActionKind) {
    ActionKindUnknown = 0,
    ActionKindCompiler,
    ActionKindFilter,
    ActionKindPostproc,
    kActionKindCount
};

ActionKind LRActionKindFromString(NSString *kindString);
NSString *LRStringFromActionKind(ActionKind kind);
NSArray *LRValidActionKindStrings();
