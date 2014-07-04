
#import <Foundation/Foundation.h>


@class Rule;
@class Action;
@class LRPackageResolutionContext;
@class Project;


extern NSString *const LRContextActionDidChangeVersionsNotification;


@interface LRContextAction : NSObject

- (id)initWithAction:(Action *)action project:(Project *)project resolutionContext:(LRPackageResolutionContext *)resolutionContext;

@property(nonatomic, readonly) Action *action;
@property(nonatomic, readonly) Project *project;
@property(nonatomic, readonly) LRPackageResolutionContext *resolutionContext;

@property(nonatomic, readonly, copy) NSArray *versions;
@property(nonatomic, readonly, copy) NSArray *versionSpecs;

- (Rule *)newInstanceWithMemento:(NSDictionary *)memento;

@end
