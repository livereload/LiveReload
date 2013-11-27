
#import <Foundation/Foundation.h>


@class Action;
@class ActionType;
@class LRPackageResolutionContext;


extern NSString *const LRContextActionTypeDidChangeVersionsNotification;


@interface LRContextActionType : NSObject

- (id)initWithActionType:(ActionType *)actionType resolutionContext:(LRPackageResolutionContext *)resolutionContext;

@property(nonatomic, readonly) ActionType *actionType;
@property(nonatomic, readonly) LRPackageResolutionContext *resolutionContext;

@property(nonatomic, readonly, copy) NSArray *versions;
@property(nonatomic, readonly, copy) NSArray *versionSpecs;

- (Action *)newInstanceWithMemento:(NSDictionary *)memento;

@end
