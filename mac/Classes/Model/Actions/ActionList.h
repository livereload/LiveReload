
#import <Foundation/Foundation.h>
#import "Action.h"


@class LRPackageResolutionContext;
@class LRContextActionType;


@interface ActionList : NSObject

@property(nonatomic, strong, readonly) NSArray *actionTypes;
@property(nonatomic, strong, readonly) LRPackageResolutionContext *resolutionContext;

@property(nonatomic, strong, readonly) NSArray *contextActionTypes;

@property(nonatomic, strong, readonly) NSArray *actions;
@property(nonatomic, strong, readonly) NSArray *compilerActions;
@property(nonatomic, strong, readonly) NSArray *filterActions;
@property(nonatomic, strong, readonly) NSArray *postprocActions;
@property(nonatomic, strong, readonly) NSArray *activeActions;
@property(nonatomic, copy) NSDictionary *memento;

- (id)initWithActionTypes:(NSArray *)actionTypes resolutionContext:(LRPackageResolutionContext *)resolutionContext;

- (void)insertObject:(Action *)object inActionsAtIndex:(NSUInteger)index;
- (void)removeObjectFromActionsAtIndex:(NSUInteger)index;
- (BOOL)canRemoveObjectFromActionsAtIndex:(NSUInteger)index;

- (void)addActionWithPrototype:(NSDictionary *)prototype;

@end
