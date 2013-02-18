using System;
//using System.Collections.Generic;
//using System.Linq;
//using System.Text;

using Microsoft.VisualBasic.ApplicationServices;

namespace LiveReload
{
    public class SingleInstanceManager : WindowsFormsApplicationBase
    {
        private App application;
        
        public SingleInstanceManager()
        {
            IsSingleInstance = true;
        }

        protected override bool OnStartup(StartupEventArgs eventArgs)
        {
            // First time _application is launched
            application = new App();
            application.InitializeComponent();
            application.Run();

            return false;
        }

        protected override void OnStartupNextInstance(StartupNextInstanceEventArgs eventArgs)
        {
            // Subsequent launches
            base.OnStartupNextInstance(eventArgs);
            application.HandleMainWindowShowEvent();
        }
    }
    
    public class EntryPoint
    {
        public static bool isRestarting = false;
        
        [STAThread]
        public static void Main(string[] args)
        {
            SingleInstanceManager manager = new SingleInstanceManager();
            manager.Run(args);
            if (isRestarting)
                System.Windows.Forms.Application.Restart(); //from System.Windows.Forms.dll
        }
    }

}
