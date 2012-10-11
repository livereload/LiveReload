using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Windows;

using System.Windows.Threading;
using System.IO;

namespace LiveReload
{
    /// <summary>
    /// Interaction logic for App.xaml
    /// </summary>
    public partial class App : Application
    {
        private MainWindow window;
        private NodeRPC nodeFoo;
        private string baseDir;

        private void Application_Startup(object sender, StartupEventArgs e)
        {
            baseDir = System.AppDomain.CurrentDomain.BaseDirectory;
            if (!File.Exists(Path.Combine(baseDir, @"res\LiveReloadNodeJs.exe")))
            {
                baseDir = Path.Combine(baseDir, @"..\..\");
            }

            nodeFoo = new NodeRPC(Dispatcher.CurrentDispatcher, baseDir);
            nodeFoo.NodeMessageEvent += HandleNodeMessageEvent;
            nodeFoo.NodeStartedEvent += HandleNodeStartedEvent;
            nodeFoo.Start();

            window = new MainWindow();
            window.ProjectAddEvent    += HandleProjectAddEvent;
            window.ProjectRemoveEvent += HandleProjectRemoveEvent;
            window.Show();

            TrayIconController trayIcon = new TrayIconController();
            //trayIcon.MainWindowHideEvent += HandleMainWindowShowEvent;
            trayIcon.MainWindowShowEvent += HandleMainWindowShowEvent;
            trayIcon.MainWindowToggleEvent  += HandleMainWindowToggleEvent;
        }

        private void HandleNodeMessageEvent(string nodeLine)
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

        private void HandleNodeStartedEvent()
        {
            string resourcesDir = baseDir + @"res\";
            string appDataDir = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + @"\LiveReload\Data\";
            string logDir = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData) + @"\LiveReload\Log\";
            string version = "0.5";
            string build = "beta";
            string platform = "windows";
            Console.WriteLine(resourcesDir);
            Console.WriteLine(appDataDir);
            Console.WriteLine(logDir);

            var foo = new object[] { "app.init", new Dictionary<string, object> {
                {"resourcesDir", resourcesDir},
                {"appDataDir",   appDataDir},
                {"logDir",       logDir},
                {"version",      version},
                {"build",        build},
                {"platform",     platform}
            } };

            string response = fastJSON.JSON.Instance.ToJSON(foo);
            Console.WriteLine(response);
            nodeFoo.NodeMessageSend(response);
        }

        private void HandleMainWindowHideEvent()
        {
            window.Hide();
        }
        private void HandleMainWindowShowEvent()
        {
            window.Show();
        }
        private void HandleMainWindowToggleEvent()
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

        private void HandleProjectAddEvent(string path)
        {
            var foo = new object[] { "projects.add", new Dictionary<string, object>{{"path", path}}};
            string response = fastJSON.JSON.Instance.ToJSON(foo);
            nodeFoo.NodeMessageSend(response);
        }
        private void HandleProjectRemoveEvent(string id)
        {
            var foo = new object[] { "projects.remove", new Dictionary<string, object> { { "id", id } } };
            string response = fastJSON.JSON.Instance.ToJSON(foo);
            nodeFoo.NodeMessageSend(response);
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
