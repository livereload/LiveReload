
#import <Foundation/Foundation.h>


@interface Action : NSObject

+ (NSString *)typeIdentifier;

@property(nonatomic, copy) NSDictionary *memento;

// automatically invoked when reading
- (void)loadFromMemento:(NSDictionary *)memento;
- (void)updateMemento:(NSMutableDictionary *)memento;

@end


@interface CustomCommandAction : Action

@property(nonatomic, copy) NSString *command;

@end


@interface UserScriptAction : Action

@property(nonatomic, copy) NSString *scriptName;

@end
