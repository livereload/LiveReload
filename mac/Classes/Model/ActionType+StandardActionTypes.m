
#import "ActionType+StandardActionTypes.h"
#import "Action.h"
#import "CustomCommandAction.h"
#import "UserScriptAction.h"
#import "AutoprefixerAction.h"

@implementation ActionType (StandardActionTypes)

+ (NSArray *)standardActionTypes {
    return @[
        [[ActionType alloc] initWithClass:[AutoprefixerAction class]],

        [[ActionType alloc] initWithClass:[CustomCommandAction class]],
        [[ActionType alloc] initWithClass:[UserScriptAction class]],
    ];
}

@end
