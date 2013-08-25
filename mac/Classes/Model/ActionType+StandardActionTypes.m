
#import "ActionType+StandardActionTypes.h"
#import "Action.h"
#import "CustomCommandAction.h"
#import "UserScriptAction.h"
#import "AutoprefixerAction.h"

@implementation ActionType (StandardActionTypes)

+ (NSArray *)standardActionTypes {
    return @[
        [[ActionType alloc] initWithClass:[AutoprefixerAction class] kind:ActionKindFilter],

        [[ActionType alloc] initWithClass:[CustomCommandAction class] kind:ActionKindPostproc],
        [[ActionType alloc] initWithClass:[UserScriptAction class] kind:ActionKindPostproc],
    ];
}

@end
