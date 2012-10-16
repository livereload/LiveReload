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
    public partial class MainWindow : MahApps.Metro.Controls.MetroWindow
    {
        public event Action MainWindowHideEvent;

        private List<ProjectData> projectsList;

        private string selectedID = null;

        public event Action<string> ProjectAddEvent;
        public event Action<string> ProjectRemoveEvent;
        public event Action<string, string, object> ProjectPropertyChangedEvent;

        public MainWindow()
        {
            InitializeComponent();
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
            MainWindowHideEvent();
        }
        public void updateTreeView(List<ProjectData> projectsList_)
        {
            projectsList = projectsList_;

            treeViewProjects.Items.Clear();
            foreach (ProjectData t in projectsList)
            {
                TreeViewItem newChild = new TreeViewItem();
                newChild.Header = t.name;
                newChild.Name   = t.id;
                treeViewProjects.Items.Add(newChild);
                if (t.id == selectedID)
                {
                    SelectItem(newChild);
                }
            }
        }

        private void treeViewProjects_SelectedItemChanged(object sender, RoutedPropertyChangedEventArgs<object> e)
        {
            if (treeViewProjects.SelectedItem != null)
            {
                int selectedIndex = treeViewProjects.Items.IndexOf(treeViewProjects.SelectedItem);
                textBlockProjectName.Text = projectsList[selectedIndex].name;
                textBlockProjectPath.Text = projectsList[selectedIndex].path;
                checkBoxCompile.IsEnabled = true;
                checkBoxRunCustom.IsEnabled = true;
                checkBoxCompile.IsChecked = projectsList[selectedIndex].compilationEnabled;
                selectedID = projectsList[selectedIndex].id;
            }
            else
            {
                textBlockProjectName.Text = "-";
                textBlockProjectPath.Text = "-";
                checkBoxCompile.IsEnabled = false;
                checkBoxRunCustom.IsEnabled = false;
                checkBoxCompile.IsChecked = false;
                checkBoxRunCustom.IsChecked = false;
            }
        }

        private void buttonProjectAdd_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new System.Windows.Forms.FolderBrowserDialog();
            System.Windows.Forms.DialogResult result = dialog.ShowDialog();
            if (result == System.Windows.Forms.DialogResult.OK)
            {
                ProjectAddEvent(dialog.SelectedPath);
            }
        }

        private int SelectedIndex()
        {
            var item = treeViewProjects.SelectedItem;
            if (item != null)
            {
                return treeViewProjects.Items.IndexOf(item);
            }
            else
            {
                return -1;
            }
        }

        private void buttonProjectRemove_Click(object sender, RoutedEventArgs e)
        {
            int selectedIndex = SelectedIndex();
            if (selectedIndex != -1)
            {
                ProjectRemoveEvent(projectsList[selectedIndex].id);
            }
        }

        private void checkBoxCompile_Click(object sender, RoutedEventArgs e)
        {
            ProjectData project = projectsList[SelectedIndex()];
            if (checkBoxCompile.IsChecked == true)
            {
                ProjectPropertyChangedEvent(project.id,"compilationEnabled",true);
            }
            else // ThreeWayState is disabled for this checkbox!
            {
                ProjectPropertyChangedEvent(project.id,"compilationEnabled",false);
            }
        }

        private void SelectItemHelper(TreeViewItem node) // unneeded ATM, retest when we will have tree depth > 1
        {
            if (node == null)
                return;
            SelectItemHelper((TreeViewItem)node.Parent);
            if (!node.IsExpanded)
            {
                node.IsExpanded = true;
                node.UpdateLayout();
            }
        }
        private void SelectItem(TreeViewItem node) // QND solution
        {
            SelectItemHelper(node.Parent as TreeViewItem);
            node.IsSelected = true;
        }

        private void buttonVersion_Click(object sender, RoutedEventArgs e)
        {
            ((App)App.Current).OpenExplorerWithLog();
        }
    }
}
