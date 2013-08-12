
#import "ActionList.h"
#import "Action.h"
#import "ActionType.h"
#import "ATFunctionalStyle.h"

@implementation ActionList {
    NSDictionary *_actionTypesByIdentifier;
    NSMutableArray *_actions;
    NSMutableDictionary *_memento;
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
    return _memento;
}

- (void)setMemento:(NSDictionary *)memento {
    _memento = [memento copy];
    [_actions removeAllObjects];

    [self insertPlaceholderAction];
    [self insertPlaceholderAction];
    [self insertPlaceholderAction];
}

- (void)insertPlaceholderAction {
    ActionType *type = _actionTypesByIdentifier[@"command"];
    [_actions addObject:[[type.klass alloc] initWithMemento:nil]];
}

- (void)insertObject:(Action *)object inActionsAtIndex:(NSUInteger)index {
    [_actions insertObject:object atIndex:index];
}

- (void)removeObjectFromActionsAtIndex:(NSUInteger)index {
    [_actions removeObjectAtIndex:index];
    if (_actions.count == 0) {
        [self insertPlaceholderAction];
    }
}

- (BOOL)canRemoveObjectFromActionsAtIndex:(NSUInteger)index {
    return YES;
}

@end
