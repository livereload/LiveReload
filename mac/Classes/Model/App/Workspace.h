
#import <Cocoa/Cocoa.h>


@class Project;


@interface Workspace : NSObject {
    NSMutableSet *_projects;
    NSDictionary *_oldMementos;

    BOOL _monitoringEnabled;
    BOOL _savingScheduled;
}

+ (Workspace *)sharedWorkspace;

@property(nonatomic, readonly, copy) NSSet *projects;
- (void)addProjectsObject:(Project *)project;
- (void)removeProjectsObject:(Project *)project;

- (Project *)projectWithPath:(NSString *)path create:(BOOL)create;

@property(nonatomic, readonly, copy) NSArray *sortedProjects;

@property(nonatomic, getter=isMonitoringEnabled) BOOL monitoringEnabled;

- (void)save;

@end
