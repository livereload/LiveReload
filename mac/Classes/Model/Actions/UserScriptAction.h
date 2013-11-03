
#import "Action.h"
#import "UserScript.h"


@interface UserScriptAction : Action

@property(nonatomic, copy) NSString *scriptName;

@property(nonatomic, readonly) UserScript *script;

@end
