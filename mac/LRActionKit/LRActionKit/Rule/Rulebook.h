@import Foundation;


@class Rule;
@class Project;
@class LRPackageResolutionContext;
@class LRContextAction;


@interface Rulebook : NSObject

@property(nonatomic, strong, readonly) NSArray *actions;
@property(nonatomic, strong, readonly) Project *project;
@property(nonatomic, strong, readonly) LRPackageResolutionContext *resolutionContext;

@property(nonatomic, strong, readonly) NSArray *contextActions;

@property(nonatomic, strong, readonly) NSArray *rules;
@property(nonatomic, strong, readonly) NSArray *compilationRules;
@property(nonatomic, strong, readonly) NSArray *filterRules;
@property(nonatomic, strong, readonly) NSArray *postprocRules;
@property(nonatomic, strong, readonly) NSArray *activeRules;
@property(nonatomic, copy) NSDictionary *memento;

- (id)initWithActions:(NSArray *)actions project:(Project *)project;

- (void)insertObject:(Rule *)object inRulesAtIndex:(NSUInteger)index;
- (void)removeObjectFromRulesAtIndex:(NSUInteger)index;
- (BOOL)canRemoveObjectFromRulesAtIndex:(NSUInteger)index;

- (void)addRuleWithPrototype:(NSDictionary *)prototype;

@end
