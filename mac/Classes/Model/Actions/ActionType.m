
#import "ActionType.h"
#import "Action.h"
#import "Errors.h"
#import "Plugin.h"
#import "LROption+Factory.h"

#import "LRManifestLayer.h"
#import "LRActionVersion.h"

#import "ATFunctionalStyle.h"



static NSString *ActionKindNames[] = {
    @"unknown",
    @"compiler",
    @"filter",
    @"postproc",
};

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


@implementation ActionType {
    NSMutableArray *_errors;
    NSArray *_manifestLayers;
    NSArray *_optionSpecs;
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

        _manifestLayers = [_options[@"defaults"] arrayByMappingElementsUsingBlock:^id(NSDictionary *info) {
            return [[LRManifestLayer alloc] initWithManifest:info];
        }];

        [self initializeWithOptions];
    }
    return self;
}

- (void)initializeWithOptions {
    

    _errorSpecs = _options[@"errors"] ?: @[];

    _optionSpecs = self.options[@"options"] ?: @[];

    // validate option specs
    for (LROption *option in [self createOptionsWithAction:nil]) {
        for (NSError *error in option.errors) {
            [self addErrorMessage:[NSString stringWithFormat:@"Invalid options for action %@: %@", _identifier, error.localizedDescription]];
        }
    }
}

+ (ActionType *)actionTypeWithOptions:(NSDictionary *)options plugin:(Plugin *)plugin {
    NSString *identifier = [options[@"id"] copy] ?: @"";
    NSString *name = [options[@"name"] copy] ?: identifier;

    NSDictionary *knownTypes = @{
        @"filter": @{
            @"kind": @"filter",
            @"objc_class":    @"FilterAction",
            @"objc_rowClass": @"FilterActionRow",
        },
        @"compile-file": @{
            @"kind": @"compiler",
            @"objc_class":    @"CompileFileAction",
            @"objc_rowClass": @"CompileFileActionRow",
        },
    };

    NSString *typeName = options[@"type"];
    if (typeName) {
        NSDictionary *typeOptions = knownTypes[typeName];

        NSMutableDictionary *mergedOptions = [NSMutableDictionary new];
        [mergedOptions addEntriesFromDictionary:typeOptions];
        [mergedOptions addEntriesFromDictionary:options];
        options = [mergedOptions copy];
    }

    ActionKind kind = LRActionKindFromString(options[@"kind"] ?: @"");

    NSString *actionClassName = options[@"objc_class"] ?: @"";
    NSString *rowClassName = options[@"objc_rowClass"] ?: @"";

    Class actionClass = NSClassFromString(actionClassName);
    Class rowClass = NSClassFromString(rowClassName);

    ActionType *result = [[self alloc] initWithIdentifier:identifier kind:kind actionClass:actionClass rowClass:rowClass options:options plugin:plugin];

    if (identifier.length == 0)
        [result addErrorMessage:@"'id' attribute is required"];

    result.name = name;

    if (kind == ActionKindUnknown)
        [result addErrorMessage:[NSString stringWithFormat:@"'kind' attribute is required and must be one of %@", LRValidActionKindStrings()]];

    if (!actionClass)
        [result addErrorMessage:[NSString stringWithFormat:@"Cannot find action class '%@'", actionClassName]];
    if (!rowClass)
        [result addErrorMessage:[NSString stringWithFormat:@"Cannot find row class '%@'", rowClassName]];

    [actionClass validateActionType:result];

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

- (NSArray *)createOptionsWithAction:(Action *)action {
    return [_optionSpecs arrayByMappingElementsUsingBlock:^id(NSDictionary *spec) {
        return [LROption optionWithSpec:spec action:action];
    }];
}

@end
