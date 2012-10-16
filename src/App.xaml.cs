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
        private string baseDir, logDir, resourcesDir, appDataDir;
        private StreamWriter logWriter;

        public static string Version
        {
            get
            {
                System.Reflection.Assembly asm = System.Reflection.Assembly.GetExecutingAssembly();

                System.Diagnostics.FileVersionInfo fvi = System.Diagnostics.FileVersionInfo.GetVersionInfo(asm.Location);
                //return String.Format("{0}.{1}", fvi.ProductMajorPart, fvi.ProductMinorPart);
                return fvi.FileVersion;
            }
        }

        private void Application_Startup(object sender, StartupEventArgs e)
        {
            baseDir = System.AppDomain.CurrentDomain.BaseDirectory;
            if (!File.Exists(Path.Combine(baseDir, @"res\LiveReloadNodeJs.exe")))
            {
                baseDir = Path.Combine(baseDir, @"..\..\");
            }

            resourcesDir = Path.Combine(baseDir, @"res\");
            appDataDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), @"LiveReload\Data\");
            logDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), @"LiveReload\Log\");

            Directory.CreateDirectory(logDir);

            string logFile = Path.Combine(logDir, "LiveReload_" + DateTime.Now.ToString("yyyy_MM_dd_HHmmss") + ".txt");
            logWriter = new StreamWriter(logFile);
            logWriter.WriteLine("LiveReload v" + Version + " says hi.");
            logWriter.WriteLine("OS version: " + Environment.OSVersion);
            logWriter.WriteLine("Paths:");
            logWriter.WriteLine("  resourcesDir  = \"" + resourcesDir + "\"");
            logWriter.WriteLine("  appDataDir    = \"" + appDataDir + "\"");
            logWriter.WriteLine("  logDir        = \"" + logDir + "\"");
            logWriter.Flush();

            nodeFoo = new NodeRPC(Dispatcher.CurrentDispatcher, baseDir, logWriter);
            nodeFoo.NodeMessageEvent += HandleNodeMessageEvent;
            nodeFoo.NodeStartedEvent += HandleNodeStartedEvent;
            nodeFoo.Start();

            window = new MainWindow();
            window.ProjectAddEvent             += HandleProjectAddEvent;
            window.ProjectRemoveEvent          += HandleProjectRemoveEvent;
            window.ProjectPropertyChangedEvent += HandleProjectPropertyChangedEvent;
            window.MainWindowHideEvent         += HandleMainWindowHideEvent;
            window.buttonVersion.Content = "v" + Version;
            window.Show();

            TrayIconController trayIcon = new TrayIconController();
            trayIcon.MainWindowHideEvent += HandleMainWindowHideEvent;
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
            string version = Version;
            string build = "beta";
            string platform = "windows";
            Console.WriteLine(resourcesDir);
            Console.WriteLine(appDataDir);
            Console.WriteLine(logDir);

            var foo = new object[] { "app.init",
                                     new Dictionary<string, object> {
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
        private void HandleProjectPropertyChangedEvent(string id, string property, object value)
        {
            var foo = new object[] { "projects.update",
                                     new Dictionary<string, object> {
                                        {"id",     id },
                                        {property, value}
            } };
            string response = fastJSON.JSON.Instance.ToJSON(foo);
            Console.WriteLine(response);
            nodeFoo.NodeMessageSend(response);
        }

        private void Application_Exit(object sender, ExitEventArgs e)
        {
            logWriter.WriteLine("LiveReload says bye.");
            logWriter.Flush();
        }
    }

    public class ProjectData
    {
        public string id { get; set; }
        public string name { get; set; }
        public string path { get; set; }
        public bool compilationEnabled { get; set; }

        public ProjectData(Dictionary<string,object> dic)
        {
            id   = (string) dic["id"];
            name = (string) dic["name"];
            path = (string) dic["path"];
            compilationEnabled = (bool) dic["compilationEnabled"];
        }
    }
}
