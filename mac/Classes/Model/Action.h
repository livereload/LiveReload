
#import <Foundation/Foundation.h>


@interface Action : NSObject

+ (NSString *)typeIdentifier;
@property(nonatomic, readonly) NSString *typeIdentifier;

- (id)initWithMemento:(NSDictionary *)memento;
@property(nonatomic, copy) NSDictionary *memento;

// automatically invoked when reading
- (void)loadFromMemento:(NSDictionary *)memento;
- (void)updateMemento:(NSMutableDictionary *)memento;

@property(nonatomic) BOOL enabled;

@property(nonatomic, readonly, getter = isNonEmpty) BOOL nonEmpty;

@end


@interface CustomCommandAction : Action

@property(nonatomic, copy) NSString *command;

@end


@interface UserScriptAction : Action

@property(nonatomic, copy) NSString *scriptName;

@end
