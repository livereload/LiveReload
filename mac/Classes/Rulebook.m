
#import "Rulebook.h"
#import "LiveReload-Swift-x.h"
#import "ActionType.h"
#import "LRContextActionType.h"
#import "Project.h"

#import "ATFunctionalStyle.h"


@implementation Rulebook {
    NSDictionary *_actionTypesByIdentifier;
    NSDictionary *_contextActionTypesByIdentifier;
    NSMutableArray *_rules;
}

- (id)initWithActionTypes:(NSArray *)actionTypes project:(Project *)project {
    self = [super init];
    if (self) {
        _actionTypes = [actionTypes copy];
        _actionTypesByIdentifier = [_actionTypes dictionaryWithElementsGroupedByKeyPath:@"identifier"];

        _project = project;

        _contextActionTypes = [actionTypes arrayByMappingElementsUsingBlock:^id(ActionType *type) {
            return [[LRContextActionType alloc] initWithActionType:type project:_project resolutionContext:self.resolutionContext];
        }];
        _contextActionTypesByIdentifier = [_contextActionTypes dictionaryWithElementsGroupedByKeyPath:@"actionType.identifier"];

        _rules = [NSMutableArray new];
    }
    return self;
}

- (NSDictionary *)memento {
    NSMutableArray *actionMementos = [NSMutableArray new];
    for (Rule *rule in _rules) {
        if (!rule.nonEmpty)
            continue;
        
        NSDictionary *actionMemento = rule.memento;
        if (actionMemento)
            [actionMementos addObject:actionMemento];
    }

    return @{@"rules": actionMementos};
}

- (void)setMemento:(NSDictionary *)memento {
    [self willChangeValueForKey:@"rules"];
    
    [_rules removeAllObjects];

    NSArray *actionMementos = memento[@"rules"] ?: (memento[@"actions"] ?: @[]);
    for (NSDictionary *actionMemento in actionMementos) {
        Rule *rule = [self actionWithMemento:actionMemento];
        if (rule)
            [_rules addObject:rule];
    }

    [self didChangeValueForKey:@"rules"];
}

- (LRPackageResolutionContext *)resolutionContext {
    return _project.resolutionContext;
}

- (Rule *)actionWithMemento:(NSDictionary *)actionMemento {
    NSString *typeIdentifier = actionMemento[@"action"];
    if (!typeIdentifier)
        return nil;

    LRContextActionType *type = _contextActionTypesByIdentifier[typeIdentifier];
    if (!type)
        return nil;

    return [type newInstanceWithMemento:actionMemento];
}

- (void)insertObject:(Rule *)object inRulesAtIndex:(NSUInteger)index {
    [_rules insertObject:object atIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
}

- (void)removeObjectFromRulesAtIndex:(NSUInteger)index {
    [_rules removeObjectAtIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
}

- (BOOL)canRemoveObjectFromRulesAtIndex:(NSUInteger)index {
    return YES;
}

- (void)addRuleWithPrototype:(NSDictionary *)prototype {
    Rule *rule = [self actionWithMemento:prototype];
    NSAssert(rule != nil, @"Invalid rule prototype: %@", prototype);
    [self insertObject:rule inRulesAtIndex:_rules.count];
}

- (NSArray *)activeRules {
    return [_rules filteredArrayUsingBlock:^BOOL(Rule *rule) {
        return rule.nonEmpty && rule.enabled;
    }];
}

+ (NSSet *)keyPathsForValuesAffectingActiveRules {
    return [NSSet setWithObject:@"rules"];
}

- (NSArray *)compilationRules {
    return [_rules filteredArrayUsingBlock:^BOOL(Rule *rule) {
        return rule.type.kind == ActionKindCompiler;
    }];
}

+ (NSSet *)keyPathsForValuesAffectingCompilationRules {
    return [NSSet setWithObject:@"rules"];
}

- (NSArray *)filterRules {
    return [_rules filteredArrayUsingBlock:^BOOL(Rule *rule) {
        return rule.type.kind == ActionKindFilter;
    }];
}

+ (NSSet *)keyPathsForValuesAffectingFilterRules {
    return [NSSet setWithObject:@"rules"];
}

- (NSArray *)postprocRules {
    return [_rules filteredArrayUsingBlock:^BOOL(Rule *rule) {
        return rule.type.kind == ActionKindPostproc;
    }];
}

+ (NSSet *)keyPathsForValuesAffectingPostprocRules {
    return [NSSet setWithObject:@"rules"];
}

@end
