
#import "ActionList.h"
#import "Action.h"
#import "ActionType.h"
#import "ATFunctionalStyle.h"

@implementation ActionList {
    NSDictionary *_actionTypesByIdentifier;
    NSMutableArray *_actions;
}

- (id)initWithActionTypes:(NSArray *)actionTypes {
    self = [super init];
    if (self) {
        _actionTypes = [actionTypes copy];
        _actionTypesByIdentifier = [_actionTypes dictionaryWithElementsGroupedByKeyPath:@"identifier"];
        _actions = [NSMutableArray new];
    }
    return self;
}

- (NSDictionary *)memento {
    NSMutableArray *actionMementos = [NSMutableArray new];
    for (Action *action in _actions) {
        if (!action.isNonEmpty)
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
        Action *action = [self actionWithMemento:actionMemento];
        if (action)
            [_actions addObject:action];
    }

    [self didChangeValueForKey:@"actions"];
}

- (Action *)actionWithMemento:(NSDictionary *)actionMemento {
    NSString *typeIdentifier = actionMemento[@"action"];
    if (!typeIdentifier)
        return nil;

    ActionType *type = _actionTypesByIdentifier[typeIdentifier];
    if (!type)
        return nil;

    return [type newInstanceWithMemento:actionMemento];
}

- (void)insertObject:(Action *)object inActionsAtIndex:(NSUInteger)index {
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
    Action *action = [self actionWithMemento:prototype];
    NSAssert(action != nil, @"Invalid action prototype: %@", prototype);
    [self insertObject:action inActionsAtIndex:_actions.count];
}

- (NSArray *)activeActions {
    return [_actions filteredArrayUsingBlock:^BOOL(Action *action) {
        return action.nonEmpty && action.enabled;
    }];
}

+ (NSSet *)keyPathsForValuesAffectingActiveActions {
    return [NSSet setWithObject:@"actions"];
}

- (NSArray *)filterActions {
    return [_actions filteredArrayUsingBlock:^BOOL(Action *action) {
        return action.type.kind == ActionKindFilter;
    }];
}

+ (NSSet *)keyPathsForValuesAffectingFilterActions {
    return [NSSet setWithObject:@"actions"];
}

- (NSArray *)postprocActions {
    return [_actions filteredArrayUsingBlock:^BOOL(Action *action) {
        return action.type.kind == ActionKindPostproc;
    }];
}

+ (NSSet *)keyPathsForValuesAffectingPostprocActions {
    return [NSSet setWithObject:@"actions"];
}

@end
