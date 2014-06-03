
#import <Foundation/Foundation.h>


@class Action;
@class ActionType;
@class LRPackageResolutionContext;
@class Project;


extern NSString *const LRContextActionTypeDidChangeVersionsNotification;


@interface LRContextActionType : NSObject

- (id)initWithActionType:(ActionType *)actionType project:(Project *)project resolutionContext:(LRPackageResolutionContext *)resolutionContext;

@property(nonatomic, readonly) ActionType *actionType;
@property(nonatomic, readonly) Project *project;
@property(nonatomic, readonly) LRPackageResolutionContext *resolutionContext;

@property(nonatomic, readonly, copy) NSArray *versions;
@property(nonatomic, readonly, copy) NSArray *versionSpecs;

- (Action *)newInstanceWithMemento:(NSDictionary *)memento;

@end
