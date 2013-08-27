
#import "ActionType.h"
#import "Action.h"
#import "Errors.h"
#import "Plugin.h"


static NSString *ActionKindNames[] = {
    @"unknown",
    @"filter",
    @"postproc",
};

ActionKind LRActionKindFromString(NSString *kindString) {
    static NSDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
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


@implementation ActionType {
    NSMutableArray *_errors;
}

- (id)initWithIdentifier:(NSString *)identifier kind:(ActionKind)kind actionClass:(Class)actionClass rowClass:(Class)rowClass options:(NSDictionary *)options plugin:(Plugin *)plugin {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _kind = kind;
        _actionClass = actionClass;
        _rowClass = rowClass;
        _options = [options copy];
        _plugin = plugin;
        _errors = [NSMutableArray new];
        _valid = YES;
    }
    return self;
}

+ (ActionType *)actionTypeWithOptions:(NSDictionary *)options plugin:(Plugin *)plugin {
    NSString *identifier = [options[@"id"] copy] ?: @"";
    ActionKind kind = LRActionKindFromString(options[@"type"] ?: @"");

    NSString *defaultActionClassName = nil;
    NSString *defaultRowClassName = nil;
    if (kind == ActionKindFilter) {
        defaultActionClassName = @"FilterAction";
        defaultRowClassName = @"FilterActionRow";
    }

    NSString *actionClassName = options[@"objc_class"] ?: defaultActionClassName;
    NSString *rowClassName = options[@"objc_rowClass"] ?: defaultRowClassName;

    Class actionClass = NSClassFromString(actionClassName);
    Class rowClass = NSClassFromString(rowClassName);

    ActionType *result = [[self alloc] initWithIdentifier:identifier kind:kind actionClass:actionClass rowClass:rowClass options:options plugin:plugin];

    if (identifier.length == 0)
        [result addErrorMessage:@"'id' attribute is required"];

    if (kind == ActionKindUnknown)
        [result addErrorMessage:[NSString stringWithFormat:@"'kind' attribute is required and must be one of %@", LRValidActionKindStrings()]];

    if (!actionClass)
        [result addErrorMessage:[NSString stringWithFormat:@"Cannot find action class '%@'", actionClassName]];
    if (!rowClass)
        [result addErrorMessage:[NSString stringWithFormat:@"Cannot find row class '%@'", rowClassName]];

    return result;
}

- (NSArray *)errors {
    return [_errors copy];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ '%@' (%@, %@)", LRStringFromActionKind(_kind), _identifier, NSStringFromClass(_actionClass), NSStringFromClass(_rowClass)];
}

- (void)addErrorMessage:(NSString *)message {
    [_plugin addErrorMessage:message];
    _valid = NO;
}

- (Action *)newInstanceWithMemento:(NSDictionary *)memento {
    return [[_actionClass alloc] initWithType:self memento:memento];
}

@end
