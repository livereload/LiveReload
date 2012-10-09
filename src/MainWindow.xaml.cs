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

namespace LiveReload
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private List<ProjectData> projectsList;

        public MainWindow()
        {
            InitializeComponent();
        }
        
        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
        }
        
        private void Hyperlink_RequestNavigate(object sender, RequestNavigateEventArgs e)
        {
            Process.Start(e.Uri.ToString());
        }
        
        public void DisplayNodeResult(string nodeLine)
        {
            textBoxNodeResult.Text = nodeLine;
            Console.WriteLine(nodeLine);
        }

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {
            e.Cancel = true;
            this.Hide();
        }
        public void updateTreeView(List<ProjectData> projectsList_)
        {
            projectsList = projectsList_;
            foreach (ProjectData t in projectsList)
            {
                TreeViewItem newChild = new TreeViewItem();
                newChild.Header = t.name;
                newChild.Name   = t.id;
                treeViewProjects.Items.Add(newChild);
            }
        }

        private void treeViewProjects_SelectedItemChanged(object sender, RoutedPropertyChangedEventArgs<object> e)
        {
            TreeViewItem selectedTVI = (TreeViewItem)treeViewProjects.SelectedItem;
            int selectedIndex = treeViewProjects.Items.IndexOf(selectedTVI);

            textBlockProjectName.Text = projectsList[selectedIndex].name;
            textBlockProjectPath.Text = projectsList[selectedIndex].path;
        }
    }
}
