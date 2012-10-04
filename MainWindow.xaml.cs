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
using System.Windows.Threading;

namespace LiveReload
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        NodeRPC nodeFoo;

        public MainWindow()
        {
            InitializeComponent();
        }

        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            nodeFoo = new NodeRPC(Dispatcher.CurrentDispatcher);
            nodeFoo.RaiseNodeLineEvent += HandleNodeLineEvent;
        }

        private void Hyperlink_RequestNavigate(object sender, RequestNavigateEventArgs e)
        {
            Process.Start(e.Uri.ToString());
        }

        void HandleNodeLineEvent(string nodeLine)
        {
            textBoxNodeResult.Text = nodeLine;
            Console.WriteLine(nodeLine);
        }
    }
}
