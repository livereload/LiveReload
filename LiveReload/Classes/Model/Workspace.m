
#import "Workspace.h"
#import "Project.h"
#import "ATFunctionalStyle.h"
#import "Preferences.h"


#define ProjectListKey @"projects"


static Workspace *sharedWorkspace;


@interface Workspace ()

- (void)load;

@end


@implementation Workspace

@synthesize projects=_projects;


#pragma mark -
#pragma mark Singleton

+ (Workspace *)sharedWorkspace {
    if (sharedWorkspace == nil) {
        sharedWorkspace = [[Workspace alloc] init];
    }
    return sharedWorkspace;
}


#pragma mark -
#pragma mark Init/dealloc

- (id)init {
    if ((self = [super init])) {
        _projects = [[NSMutableSet alloc] init];
        [self load];
    }
    return self;
}

// just to make XDry happy; won't ever be deallocated
- (void)dealloc {
    [_projects release], _projects = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Persistence

- (void)save {
    NSArray *projectMementos = [[_projects allObjects] arrayByMappingElementsToValueOfKeyPath:@"memento"];
    [[NSUserDefaults standardUserDefaults] setObject:projectMementos forKey:ProjectListKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)load {
    NSArray *projectMementos = [[NSUserDefaults standardUserDefaults] objectForKey:ProjectListKey];
    [_projects removeAllObjects];
    [_projects addObjectsFromArray:[projectMementos arrayByMappingElementsUsingBlock:^id(id value) {
        return [[[Project alloc] initWithMemento:value] autorelease];
    }]];
}


#pragma mark -
#pragma mark Projects set KVC accessors

- (void)addProjectsObject:(Project *)project {
    NSParameterAssert(![_projects containsObject:project]);
    [_projects addObject:project];
    if (_monitoringEnabled) {
        project.monitoringEnabled = YES;
    }
    [self save];
}

- (void)removeProjectsObject:(Project *)project {
    NSParameterAssert([_projects containsObject:project]);
    project.monitoringEnabled = NO;
    [_projects removeObject:project];
    [self save];
}

- (NSArray *)sortedProjects {
    return [[self.projects allObjects] sortedArrayUsingSelector:@selector(path)];
}


#pragma mark -
#pragma mark File System Monitoring

- (BOOL)isMonitoringEnabled {
    return _monitoringEnabled;
}

- (void)setMonitoringEnabled:(BOOL)shouldMonitor {
    if (_monitoringEnabled != shouldMonitor) {
        _monitoringEnabled = shouldMonitor;
        for (Project *project in _projects) {
            project.monitoringEnabled = _monitoringEnabled;
        }
    }
}


@end
