using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;

using Twins;
using LiveReload.Model;

namespace LiveReload
{
    public class ProjectViewModel
    {
        public string Text { get; set; }
    }

    public class MainWindowViewModel : ModelBase
    {
        private Workspace workspace;
        private ActionsFilesViewModel actionsFiles = new ActionsFilesViewModel();
        private Project selectedProject;

        private string statusMessage = "Starting up...";

        // design-time only
        // need to be careful for workspace not to perform any dangerous activity!
        public MainWindowViewModel() {
            this.workspace = new Workspace();
            //workspace.AddProject(new Project("", "LiveReload-less-example-2"));
            //workspace.AddProject(new Project("", "Project2"));
        }

        public MainWindowViewModel(Workspace sharedWorkspace) {
            this.workspace = sharedWorkspace;
        }

        public ActionsFilesViewModel ActionsFiles {
            get {
                return actionsFiles;
            }
        }

        public string StatusMessage {
            get {
                return statusMessage;
            }
            set {
                statusMessage = value;
                OnPropertyChanged("StatusMessage");
            }
        }

        public bool IsProjectSelected {
            get {
                return (SelectedProject != null);
            }
        }

        public Project SelectedProject {
            get {
                return selectedProject;
            }
            set {
                selectedProject = value;
                OnPropertyChanged("SelectedProject");
                OnPropertyChanged("IsProjectSelected");
            }
        }

        public ReadOnlyObservableCollection<Project> Projects {
            get {
                return workspace.Projects;
            }
        }

        public ObservableCollection<ActionGroup> ActionGroups {
            get {
                return actionsFiles.Groups;
            }
        }

        public Workspace Workspace {
            get {
                return workspace;
            }
        }
    }
}
