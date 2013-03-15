using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace LiveReload
{
    public class ProjectViewModel
    {
        public string Name {
            get {
                return "";
            }
        }
    }

    public class MainWindowViewModel
    {
        public List<ProjectViewModel> SampleItems {
            get {
                return new ProjectViewModel[0].ToList();
            }
        }
    }
}
