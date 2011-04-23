
#import <Cocoa/Cocoa.h>


@class Project;


@interface Workspace : NSObject {
    NSMutableSet *_projects;
}

+ (Workspace *)sharedWorkspace;

@property(nonatomic, readonly, copy) NSSet *projects;
- (void)addProjectsObject:(Project *)project;
- (void)removeProjectsObject:(Project *)project;

@end
