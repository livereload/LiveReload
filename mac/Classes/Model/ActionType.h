
#import <Foundation/Foundation.h>


@class Plugin;
@class Action;


typedef enum {
    ActionKindUnknown = 0,
    ActionKindFilter,
    ActionKindPostproc,
    kActionKindCount
} ActionKind;

ActionKind LRActionKindFromString(NSString *kindString);
NSString *LRStringFromActionKind(ActionKind kind);
NSArray *LRValidActionKindStrings();


@interface ActionType : NSObject

@property(nonatomic, strong) Plugin *plugin;
@property(nonatomic, assign) Class actionClass;
@property(nonatomic, assign) Class rowClass;
@property(nonatomic, strong) NSDictionary *options;
@property(nonatomic, readonly, strong) NSArray *errors;
@property(nonatomic, readonly) BOOL valid;

@property(nonatomic) ActionKind kind;
@property(nonatomic, copy) NSString *identifier;

- (id)initWithIdentifier:(NSString *)identifier kind:(ActionKind)kind actionClass:(Class)actionClass rowClass:(Class)rowClass options:(NSDictionary *)options plugin:(Plugin *)plugin;
+ (ActionType *)actionTypeWithOptions:(NSDictionary *)options plugin:(Plugin *)plugin;

- (void)addErrorMessage:(NSString *)message;

- (Action *)newInstanceWithMemento:(NSDictionary *)memento;

@end
