using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

using System.Diagnostics;
using System.IO;

using D = System.Collections.Generic.Dictionary<string, object>;

namespace LiveReload
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : MahApps.Metro.Controls.MetroWindow
    {
        public event Action MainWindowHideEvent;

        public event Action<string> NodeMessageEvent;

        string debugSimulatedMessage;

        public MainWindow()
        {
            InitializeComponent();
        }

        private void Hyperlink_RequestNavigate(object sender, RequestNavigateEventArgs e)
        {
            Process.Start(e.Uri.ToString());
        }

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {
            App.Current.Shutdown();
        }

        private void buttonVersion_Click(object sender, RoutedEventArgs e)
        {
            App app = (App)App.Current;
            if (app.CanRestartBackend)
                app.RestartBackend();
            else
                ((App)App.Current).OpenExplorerWithLog();
        }

        private void MetroWindow_StateChanged(object sender, EventArgs e)
        {
            this.WindowState = System.Windows.WindowState.Normal;
            MainWindowHideEvent();
        }

        private void buttonSupport_Click(object sender, RoutedEventArgs e)
        {
            Process.Start(@"http://feedback.livereload.com/");
        }

        private void MetroWindow_Loaded(object sender, RoutedEventArgs e)
        {
            TreeViewItem item = new TreeViewItem();
            item.Header = "foo.less -> foo.css";
            treeViewPaths.Items.Add(item);
        }

        private void treeViewProjects_Drop(object sender, DragEventArgs e)
        {
            //if (e.Data.GetDataPresent(DataFormats.FileDrop, false))
            //{
            //    var droppedFileNames = (string[])e.Data.GetData(DataFormats.FileDrop, false);
            //    foreach (string name in droppedFileNames)
            //        if (Directory.Exists(name))
            //        {
            //            ProjectAddEvent(name);
            //        }
            //}
        }

        public void chooseOutputFolder(D options, ObjectRPC.PayloadDelegate reply)
        {
            var dialog = new System.Windows.Forms.FolderBrowserDialog();

            string initial = (string)options["initial"];
            if (initial != null)
                dialog.SelectedPath = initial;

            System.Windows.Forms.DialogResult result = dialog.ShowDialog();
            if (result == System.Windows.Forms.DialogResult.OK)
            {
                reply(new D { {"ok", true}, {"path", dialog.SelectedPath } });
            }
            else
            {
                reply(new D { {"ok", false } });
            }
        }

        private void buttonSimulateNodeEvent_Click(object sender, RoutedEventArgs e)
        {
            debugSimulatedMessage = Microsoft.VisualBasic.Interaction.InputBox("Simulated message from Node:\n(F3 in main window to invoke)","",debugSimulatedMessage);
            if (debugSimulatedMessage == "")
                debugSimulatedMessage = null;
        }

        private void MetroWindow_KeyDown(object sender, KeyEventArgs e)
        {
            if ((e.Key == Key.F3) && (debugSimulatedMessage != null))
            {
                this.NodeMessageEvent(debugSimulatedMessage);
                Console.WriteLine("Simulated message: " + debugSimulatedMessage);
            }
        }

        private void UpdateMenuItem_Click(object sender, RoutedEventArgs e) {
            InstallUpdateSyncWithInfo();
        }

        private void ShowReleaseNotes_Click(object sender, RoutedEventArgs e) {
            if (gridProgress.Visibility == Visibility.Visible)
                gridProgress.Visibility = Visibility.Hidden;
            else
                gridProgress.Visibility = Visibility.Visible;
        }
    }
}
