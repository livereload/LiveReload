using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Windows;

using System.Windows.Threading;

namespace LiveReload
{
    /// <summary>
    /// Interaction logic for App.xaml
    /// </summary>
    public partial class App : Application
    {
        MainWindow window;

        private void Application_Startup(object sender, StartupEventArgs e)
        {
            NodeRPC nodeFoo = new NodeRPC(Dispatcher.CurrentDispatcher);
            nodeFoo.RaiseNodeLineEvent += HandleNodeLineEvent;

            window = new MainWindow();
            window.Show();

            TrayIconController trayIcon = new TrayIconController();
            //trayIcon.MainWindowHideEvent += HandleMainWindowShowEvent;
            trayIcon.MainWindowShowEvent += HandleMainWindowShowEvent;
            trayIcon.MainWindowToggleEvent  += HandleMainWindowToggleEvent;
        }

        void HandleNodeLineEvent(string nodeLine)
        {
            window.DisplayNodeResult(nodeLine);

            var b = (object[])fastJSON.JSON.Instance.ToObject(nodeLine);
            string messageType = (string) b[0];
            if (messageType == "update")
            {
                var messageArg = (Dictionary<string, object>) b[1];
                var rawProjects = (List<object>)messageArg["projects"];

                var projectsList = new List<ProjectData>();
                foreach (var rawProject in rawProjects)
                {
                    projectsList.Add(new ProjectData((Dictionary<string, object>) rawProject));
                }
                window.updateTreeView(projectsList);
            }
        }

        void HandleMainWindowHideEvent()
        {
            window.Hide();
        }
        void HandleMainWindowShowEvent()
        {
            window.Show();
        }
        void HandleMainWindowToggleEvent()
        {
            if (window.IsVisible)
            {
                window.Hide();
            }
            else
            {
                window.Show();
            }
        }
    }

    public class ProjectData
    {
        public string id { get; set; }
        public string name { get; set; }
        public string path { get; set; }

        public ProjectData(Dictionary<string,object> dic)
        {
            id   = (string) dic["id"];
            name = (string) dic["name"];
            path = (string) dic["path"];
        }
    }
}
