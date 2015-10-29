#import "ActionKitGlobals.h"

NSString *const LRRuleEffectiveVersionDidChangeNotification = @"LRRuleEffectiveVersionDidChange";


static NSString *ActionKindNames[] = {
    @"unknown",
    @"compiler",
    @"filter",
    @"postproc",
};

static const int kActionKindCount = sizeof(ActionKindNames) / sizeof(ActionKindNames[0]);

ActionKind LRActionKindFromString(NSString *kindString) {
    static NSDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
                @"compiler": @(ActionKindCompiler),
                @"filter": @(ActionKindFilter),
                @"postproc": @(ActionKindPostproc),
                };
    });
    return [map[kindString] intValue];  // gives 0 aka ActionKindUnknown for unknown names
}

NSString *LRStringFromActionKind(ActionKind kind) {
    NSCParameterAssert(kind < kActionKindCount);
    return ActionKindNames[kind];
}

NSArray *LRValidActionKindStrings() {
    return [NSArray arrayWithObjects:ActionKindNames+1 count:kActionKindCount-1];
}


NSString *const ActionKitErrorDomain = @"LRActionKit";
