using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using Twins;

namespace LiveReload.Model
{
    public class Workspace : ModelBase
    {
        private ObservableCollection<Project> projects = new ObservableCollection<Project>();
        private ReadOnlyObservableCollection<Project> projectsRO;
        //NSDictionary* _oldMementos;

        private bool monitoringEnabled;
        private bool savingScheduled;

        public bool MonitoringEnabled {
            get { return monitoringEnabled; }
            set {
                if (monitoringEnabled != value) {
                    monitoringEnabled = value;
                    //for (Project project in _projects) {
                    ////    [project requestMonitoring:shouldMonitor forKey:ClientConnectedMonitoringKey];
                    //}
                }
            }
        }

        public Workspace() {
            projectsRO = new ReadOnlyObservableCollection<Project>(projects);
            // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSomethingChanged:) name:@"SomethingChanged" object:nil];
            // [self load];
        }

        public ReadOnlyObservableCollection<Project> Projects {
            get {
                return projectsRO;
            }
        }

        /*
          #pragma mark Projects set KVC accessors
         * TODO: Apply KVC here
        */
        public void AddProject(Project project) {
            projects.Add(project);
            //[project requestMonitoring:_monitoringEnabled forKey:ClientConnectedMonitoringKey];
            //project.checkBrokenPaths(); // in case we don't have monitoring enabled
            this.SetNeedsSaving();
        }

        public void RemoveProject(Project project) {
            if (projects.Remove(project)) {
                //project.ceaseAllMonitoring;
                this.SetNeedsSaving();
            }
        }

        private void SetNeedsSaving() {
            if (savingScheduled)
                return;
            savingScheduled = true;
            //[self performSelector:@selector(save) withObject:nil afterDelay:0.1];
        }
    }
}



/*

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
#pragma mark Persistence

- (NSString *)dataFilePath {
    return [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"LiveReload/Data/livereload.json"];
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
    [self sendModelToBackend];
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

*/