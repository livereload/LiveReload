
#import <Foundation/Foundation.h>
#import "Action.h"


@interface ActionList : NSObject

@property(nonatomic, strong, readonly) NSArray *actionTypes;
@property(nonatomic, strong, readonly) NSArray *actions;
@property(nonatomic, strong, readonly) NSArray *activeActions;
@property(nonatomic, copy) NSDictionary *memento;

- (id)initWithActionTypes:(NSArray *)actionTypes;

- (void)insertObject:(Action *)object inActionsAtIndex:(NSUInteger)index;
- (void)removeObjectFromActionsAtIndex:(NSUInteger)index;
- (BOOL)canRemoveObjectFromActionsAtIndex:(NSUInteger)index;

- (void)addActionWithPrototype:(NSDictionary *)prototype;

@end
