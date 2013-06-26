using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Text;
using Twins;
using LiveReload.Utilities;
using System.Windows.Threading;
using D = System.Collections.Generic.IDictionary<string, object>;
using L = System.Collections.Generic.IList<object>;

namespace LiveReload.Model
{
    public class Workspace : ModelBase
    {
        private ObservableCollection<Project> projects = new ObservableCollection<Project>();
        private ReadOnlyObservableCollection<Project> projectsRO;

        private Dispatcher dispatcher;

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

        //design-time only!!
        public Workspace() {
            projectsRO = new ReadOnlyObservableCollection<Project>(projects);
            // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSomethingChanged:) name:@"SomethingChanged" object:nil];
            this.Load();
        }

        public Workspace(Dispatcher dispatcher) {
            this.dispatcher = dispatcher;
            projectsRO = new ReadOnlyObservableCollection<Project>(projects);
            // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSomethingChanged:) name:@"SomethingChanged" object:nil];
            this.Load();
        }

        public ReadOnlyObservableCollection<Project> Projects {
            get {
                return projectsRO;
            }
        }

        private void Project_PropertyChanged(object sender, PropertyChangedEventArgs e) {
            this.SetNeedsSaving();
        }

        /*
          #pragma mark Projects set KVC accessors
         * TODO: Apply KVC here
        */
        public void AddProject(Project project) {
            InitProject(project);
            projects.Add(project);
            //[project requestMonitoring:_monitoringEnabled forKey:ClientConnectedMonitoringKey];
            //project.checkBrokenPaths(); // in case we don't have monitoring enabled
            this.SetNeedsSaving();
        }

        public void RemoveProject(Project project) {
            if (projects.Remove(project)) {
                DisposeProject(project);
                //project.ceaseAllMonitoring;
                this.SetNeedsSaving();
            }
        }


        private void InitProject(Project project) {
            project.PropertyChanged += Project_PropertyChanged;
        }

        private void DisposeProject(Project project) {
            project.PropertyChanged -= Project_PropertyChanged;
            project.Dispose();
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
#pragma mark Persistence

*/
        private string DataFilePath {
            get {
                return Path.Combine(App.Current.AppDataDir, @"projects.json");
            }
        }

        public void Save() {
            string dataFilePath = this.DataFilePath;
 
            var projectMementos = new List<D>();
            foreach (Project project in projectsRO) {
                var projectMemento = project.Memento;
                projectMemento.Add("path", project.Path);
                projectMementos.Add(projectMemento);
            }
            var memento = new Dictionary<string, object> { {"projects", projectMementos} };
            string dump = Twins.JSON.Json.Stringify(memento); // Beautifier in fastJSON is broken as fuck
            File.WriteAllText(dataFilePath, dump, Encoding.UTF8);
        
            savingScheduled = false;
            Console.WriteLine(@"Workspace saved.");
            // [self sendModelToBackend];
        }


        private void SetNeedsSaving() {
            if (savingScheduled)
                return;
            savingScheduled = true;
            dispatcher.InvokeAfterDelay(TimeSpan.FromMilliseconds(100), Save);
        }

        public void Load() {
            if (!File.Exists(DataFilePath))
                return;
    
            List<D> projectMementos = new List<D>();

            string data = File.ReadAllText(DataFilePath, Encoding.UTF8);
            if (data.Length > 0) {
                var json = (D)Twins.JSON.Json.Parse(data);
                var projectsJson = (L)json.GetValueOrDefault("projects");
                if (projectsJson != null) {
                    projectMementos = projectsJson.Cast<D>().ToList();
                }
            }

            foreach(Project project in projects) {
                DisposeProject(project);
            }
            projects.Clear();
            foreach (D projectMemento in projectMementos) {
                var project = new Project((string)projectMemento["path"], projectMemento);
                InitProject(project);
                projects.Add(project);
            }
        }

/*
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
    }
}
