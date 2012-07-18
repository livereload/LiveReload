
#import "nodeapp.h"
#import "Workspace.h"
#import "Project.h"
#import "Preferences.h"

#import "ATFunctionalStyle.h"
#import "NSData+Base64.h"
#import "jansson.h"


#define ProjectListKey @"projects20a3"


static Workspace *sharedWorkspace;

static NSString *ClientConnectedMonitoringKey = @"clientConnected";


@interface Workspace ()

- (void)load;

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

- (NSString *)dataFilePath {
    return [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Data/livereload.json"];
}

- (void)save {
    NSString *dataFilePath = [self dataFilePath];
    [[NSFileManager defaultManager] createDirectoryAtPath:[dataFilePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    
    NSMutableArray *projectMementos = [NSMutableArray array];
    for (Project *project in _projects) {
        NSMutableDictionary *memento = [project memento];
        NSError *error = nil;
        NSString *bookmark = [[[NSURL fileURLWithPath:project.path] bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error] base64EncodedString];
        [memento setObject:project.path forKey:@"path"];
        [memento setObject:bookmark forKey:@"bookmark"];
        [projectMementos addObject:memento];
    }
    json_t *json = nodeapp_objc_to_json(projectMementos);
    char *dump = json_dumps(json, JSON_INDENT(2));
    [[NSData dataWithBytesNoCopy:dump length:strlen(dump) freeWhenDone:NO] writeToFile:dataFilePath options:NSDataWritingAtomic error:NULL];
    free(dump);
    json_decref(json);
    
//    [[NSUserDefaults standardUserDefaults] setObject:projectMementos forKey:ProjectListKey];
//    [[NSUserDefaults standardUserDefaults] synchronize];
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
    _oldMementos = [[[NSUserDefaults standardUserDefaults] objectForKey:ProjectListKey] retain];
    
    NSArray *projectMementos = nil;

    NSString *data = [NSString stringWithContentsOfFile:[self dataFilePath] encoding:NSUTF8StringEncoding error:NULL];
    if (data) {
        json_error_t err;
        json_t *json = json_loads([data UTF8String], 0, &err);
        projectMementos = nodeapp_json_to_objc(json, YES);
        json_decref(json);
    }

    [_projects removeAllObjects];
    for (NSDictionary *projectMemento in projectMementos) {
        NSString *bookmark = [projectMemento objectForKey:@"bookmark"];
        BOOL stale = NO;
        NSError *error = nil;
        NSURL *url = [NSURL URLByResolvingBookmarkData:[NSData dataFromBase64String:bookmark] options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&stale error:&error];
        if ([url isFileURL]) {
            [url startAccessingSecurityScopedResource];                       
            NSString *path = [url path];
            [_projects addObject:[[[Project alloc] initWithPath:path memento:projectMemento] autorelease]];
        }
    }
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


@end
