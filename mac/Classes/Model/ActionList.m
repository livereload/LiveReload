
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
        NSString *typeIdentifier = actionMemento[@"action"];
        if (!typeIdentifier)
            continue;

        ActionType *type = _actionTypesByIdentifier[@"command"];
        if (!type)
            continue;

        [_actions addObject:[[type.klass alloc] initWithMemento:actionMemento]];
    }

    [self didChangeValueForKey:@"actions"];
}

- (void)insertObject:(Action *)object inActionsAtIndex:(NSUInteger)index {
    [_actions insertObject:object atIndex:index];
}

- (void)removeObjectFromActionsAtIndex:(NSUInteger)index {
    [_actions removeObjectAtIndex:index];
}

- (BOOL)canRemoveObjectFromActionsAtIndex:(NSUInteger)index {
    return YES;
}

@end
