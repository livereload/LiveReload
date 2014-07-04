
#import "ActionList.h"
#import "LiveReload-Swift-x.h"
#import "ActionType.h"
#import "LRContextActionType.h"
#import "Project.h"

#import "ATFunctionalStyle.h"


@implementation ActionList {
    NSDictionary *_actionTypesByIdentifier;
    NSDictionary *_contextActionTypesByIdentifier;
    NSMutableArray *_actions;
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

        _actions = [NSMutableArray new];
    }
    return self;
}

- (NSDictionary *)memento {
    NSMutableArray *actionMementos = [NSMutableArray new];
    for (Rule *action in _actions) {
        if (!action.nonEmpty)
            continue;
        
        NSDictionary *actionMemento = action.memento;
        if (actionMemento)
            [actionMementos addObject:actionMemento];
    }

    return @{@"actions": actionMementos};
}

- (void)setMemento:(NSDictionary *)memento {
    [self willChangeValueForKey:@"actions"];
    
    [_actions removeAllObjects];

    NSArray *actionMementos = memento[@"actions"] ?: @[];
    for (NSDictionary *actionMemento in actionMementos) {
        Rule *action = [self actionWithMemento:actionMemento];
        if (action)
            [_actions addObject:action];
    }

    [self didChangeValueForKey:@"actions"];
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

- (void)insertObject:(Rule *)object inActionsAtIndex:(NSUInteger)index {
    [_actions insertObject:object atIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
}

- (void)removeObjectFromActionsAtIndex:(NSUInteger)index {
    [_actions removeObjectAtIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
}

- (BOOL)canRemoveObjectFromActionsAtIndex:(NSUInteger)index {
    return YES;
}

- (void)addActionWithPrototype:(NSDictionary *)prototype {
    Rule *action = [self actionWithMemento:prototype];
    NSAssert(action != nil, @"Invalid action prototype: %@", prototype);
    [self insertObject:action inActionsAtIndex:_actions.count];
}

- (NSArray *)activeActions {
    return [_actions filteredArrayUsingBlock:^BOOL(Rule *action) {
        return action.nonEmpty && action.enabled;
    }];
}

+ (NSSet *)keyPathsForValuesAffectingActiveActions {
    return [NSSet setWithObject:@"actions"];
}

- (NSArray *)compilerActions {
    return [_actions filteredArrayUsingBlock:^BOOL(Rule *action) {
        return action.type.kind == ActionKindCompiler;
    }];
}

- (NSArray *)filterActions {
    return [_actions filteredArrayUsingBlock:^BOOL(Rule *action) {
        return action.type.kind == ActionKindFilter;
    }];
}

+ (NSSet *)keyPathsForValuesAffectingFilterActions {
    return [NSSet setWithObject:@"actions"];
}

- (NSArray *)postprocActions {
    return [_actions filteredArrayUsingBlock:^BOOL(Rule *action) {
        return action.type.kind == ActionKindPostproc;
    }];
}

+ (NSSet *)keyPathsForValuesAffectingPostprocActions {
    return [NSSet setWithObject:@"actions"];
}

@end
