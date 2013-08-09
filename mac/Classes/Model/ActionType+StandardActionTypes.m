
#import "ActionType+StandardActionTypes.h"
#import "Action.h"

@implementation ActionType (StandardActionTypes)

+ (NSArray *)standardActionTypes {
    return @[
        [[ActionType alloc] initWithClass:[CustomCommandAction class]],
        [[ActionType alloc] initWithClass:[UserScriptAction class]],
    ];
}

@end
