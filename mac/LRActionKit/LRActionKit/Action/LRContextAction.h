@import Foundation;


@class Rule;
@class Action;
@class LRPackageResolutionContext;
@protocol ProjectContext;


extern NSString *const LRContextActionDidChangeVersionsNotification;


@interface LRContextAction : NSObject

- (id)initWithAction:(Action *)action project:(id<ProjectContext>)project resolutionContext:(LRPackageResolutionContext *)resolutionContext;

@property(nonatomic, readonly) Action *action;
@property(nonatomic, readonly) id<ProjectContext> project;
@property(nonatomic, readonly) LRPackageResolutionContext *resolutionContext;

@property(nonatomic, readonly, copy) NSArray *versions;
@property(nonatomic, readonly, copy) NSArray *versionSpecs;

- (Rule *)newInstanceWithMemento:(NSDictionary *)memento;

@end
