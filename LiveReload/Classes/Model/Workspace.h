
#import <Cocoa/Cocoa.h>


@class Project;


@interface Workspace : NSObject {
    NSMutableSet *_projects;

    BOOL _monitoringEnabled;
}

+ (Workspace *)sharedWorkspace;

@property(nonatomic, readonly, copy) NSSet *projects;
- (void)addProjectsObject:(Project *)project;
- (void)removeProjectsObject:(Project *)project;

@property(nonatomic, readonly, copy) NSArray *sortedProjects;

@property(nonatomic, getter=isMonitoringEnabled) BOOL monitoringEnabled;

- (void)save;

@end
