
#import "Workspace.h"
#import "Project.h"
#import "Preferences.h"

#import "OldFSTree.h"

#import "ATFunctionalStyle.h"

#import "jansson.h"
#import "nodeapp.h"
#import "nodeapp_rpc_proxy.h"


#define ProjectListKey @"projects20a3"


static Workspace *sharedWorkspace;

static NSString *ClientConnectedMonitoringKey = @"clientConnected";


@interface Workspace ()

- (void)load;

- (void)sendModelToBackend;

@end


void C_workspace__set_monitoring_enabled(json_t *arg) {
    [Workspace sharedWorkspace].monitoringEnabled = json_is_true(arg);
}


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
    [self sendModelToBackend];
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

- (Project *)projectWithPath:(NSString *)path create:(BOOL)create {
    path = [[[path stringByExpandingTildeInPath] stringByStandardizingPath] stringByResolvingSymlinksInPath];
    for (Project *project in _projects) {
        if ([[[project.path stringByStandardizingPath] stringByResolvingSymlinksInPath] isEqualToString:path]) {
            return project;
        }
    }
    if (create) {
        Project *project = [[[Project alloc] initWithPath:path memento:nil] autorelease];
        [self addProjectsObject:project];
        return project;
    } else {
        return nil;
    }
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


#pragma mark - Backend sync

- (void)sendModelToBackend {
    id memento = [[NSUserDefaults standardUserDefaults] objectForKey:ProjectListKey];
    if (!memento)
        memento = [NSDictionary dictionary];
    json_t *memento_json = nodeapp_objc_to_json(memento);
    S_app_reload_legacy_projects(memento_json);
}

void C_app__request_model(json_t *arg) {
    [[Workspace sharedWorkspace] sendModelToBackend];
}

json_t *C_project__path_of_best_file_matching_path_suffix(json_t *arg) {
    NSString *path = json_object_get_nsstring(arg, "project");
    NSString *suffix = json_object_get_nsstring(arg, "suffix");
    Project *project = [[Workspace sharedWorkspace] projectWithPath:path create:NO];
    if (project) {
        NSString *path = [[project obtainTree] pathOfBestFileMatchingPathSuffix:suffix preferringSubtree:nil];
        if (path)
            return json_object_2("found", json_true(), "file", json_nsstring(path));
        else
            return json_object_1("found", json_false());
    } else {
        return json_object_1("err", json_string("Project not found"));
    }
}

@end
