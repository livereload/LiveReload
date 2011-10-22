
#import "Workspace.h"
#import "Project.h"
#import "Preferences.h"

#import "ATFunctionalStyle.h"


#define ProjectListKey @"projects20a3"


static Workspace *sharedWorkspace;

static NSString *ClientConnectedMonitoringKey = @"clientConnected";


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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSomethingChanged:) name:@"SomethingChanged" object:nil];
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
    NSDictionary *projectMementos = [[[[_projects allObjects] dictionaryWithElementsGroupedByKeyPath:@"path"] dictionaryByMappingKeysToSelector:@selector(stringByAbbreviatingWithTildeInPath)] dictionaryByMappingValuesToSelector:@selector(memento)];
    [[NSUserDefaults standardUserDefaults] setObject:projectMementos forKey:ProjectListKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _savingScheduled = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(save) object:nil];
    NSLog(@"Workspace saved.");
}

- (void)setNeedsSaving {
    if (_savingScheduled)
        return;
    _savingScheduled = YES;
    [self performSelector:@selector(save) withObject:nil afterDelay:0.1];
}

- (void)load {
    NSDictionary *projectMementos = [[NSUserDefaults standardUserDefaults] objectForKey:ProjectListKey];
    [_projects removeAllObjects];
    [projectMementos enumerateKeysAndObjectsUsingBlock:^(id path, id projectMemento, BOOL *stop) {
        [_projects addObject:[[[Project alloc] initWithPath:[path stringByExpandingTildeInPath] memento:projectMemento] autorelease]];
    }];
}

- (void)handleSomethingChanged:(NSNotification *)notification {
    [self setNeedsSaving];
}


#pragma mark -
#pragma mark Projects set KVC accessors

- (void)addProjectsObject:(Project *)project {
    NSParameterAssert(![_projects containsObject:project]);
    [_projects addObject:project];
    [project requestMonitoring:_monitoringEnabled forKey:ClientConnectedMonitoringKey];
    [project checkBrokenPaths]; // in case we don't have monitoring enabled
    [self setNeedsSaving];
}

- (void)removeProjectsObject:(Project *)project {
    NSParameterAssert([_projects containsObject:project]);
    [project ceaseAllMonitoring];
    [_projects removeObject:project];
    [self setNeedsSaving];
}

- (NSArray *)sortedProjects {
    return [[self.projects allObjects] sortedArrayUsingSelector:@selector(compareByDisplayPath:)];
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
            [project requestMonitoring:shouldMonitor forKey:ClientConnectedMonitoringKey];
        }
    }
}


@end
