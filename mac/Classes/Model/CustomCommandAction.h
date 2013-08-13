
#import "Action.h"


@interface CustomCommandAction : Action

@property(nonatomic, copy) NSString *command;
@property(nonatomic, readonly) NSString *singleLineCommand;

@end
