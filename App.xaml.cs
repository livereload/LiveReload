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

        void HandleNodeLineEvent(string nodeLine)
        {
            window.DisplayNodeResult(nodeLine);
        }

        private void Application_Startup(object sender, StartupEventArgs e)
        {
            NodeRPC nodeFoo = new NodeRPC(Dispatcher.CurrentDispatcher);
            nodeFoo.RaiseNodeLineEvent += HandleNodeLineEvent;
            
            window = new MainWindow();
            window.Show();
        }
    }
}
