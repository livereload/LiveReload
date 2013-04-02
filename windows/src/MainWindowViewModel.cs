using LiveReload.Twins;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;

namespace LiveReload
{
    public class ProjectViewModel
    {
        public string Text { get; set; }
    }

    public class MainWindowViewModel : ModelBase
    {
        private ObservableCollection<ProjectViewModel> projects = new ObservableCollection<ProjectViewModel>();
        private ActionsFilesViewModel actionsFiles = new ActionsFilesViewModel();
        private string dummy = "123";
        
        // design-time only
        public MainWindowViewModel() {
            projects.Add(new ProjectViewModel { Text = "LiveReload-less-example-2" });
            projects.Add(new ProjectViewModel { Text = "Project2" });
        }

        public MainWindowViewModel(bool live) {
        }

        public ActionsFilesViewModel ActionsFiles {
            get {
                return actionsFiles;
            }
        }

        public ObservableCollection<ProjectViewModel> SampleItems {
            get {
                return projects;
            }
        }

        public string Dummy {
            get {
                return dummy;
            }
            set {
                if (dummy != value) {
                    dummy = value;
                    OnPropertyChanged("Dummy");
                }
            }
        }
    }
}
