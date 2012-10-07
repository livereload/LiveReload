using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.Windows;
using System.Windows.Forms;
using System.Drawing;



namespace LiveReload
{
    class TrayIconController
    {
        MainWindow window;
        private System.Windows.Forms.NotifyIcon myNotifyIcon;
        private ContextMenu contextMenuTray = new ContextMenu();

        public TrayIconController(MainWindow window_)
        {
            window = window_;

            MenuItem menuItemRestore = new MenuItem("&Restore");
            MenuItem menuItemExit    = new MenuItem("E&xit");

            menuItemRestore.Click += new EventHandler(menuItemRestore_Click);
            menuItemExit.Click    += new EventHandler(menuItemExit_Click);

            contextMenuTray.MenuItems.Add(menuItemRestore);
            contextMenuTray.MenuItems.Add(menuItemExit);

            myNotifyIcon = new System.Windows.Forms.NotifyIcon();
            myNotifyIcon.Icon = new System.Drawing.Icon(@"img/LiveReload.ico");
            myNotifyIcon.MouseClick += new System.Windows.Forms.MouseEventHandler(MyNotifyIcon_MouseClick);
            myNotifyIcon.ContextMenu = contextMenuTray;
            myNotifyIcon.Visible = true;
        }

        void menuItemRestore_Click(object sender, EventArgs e)
        {
            window.WindowState = WindowState.Normal;
            window.ShowInTaskbar = true;
        }

        void menuItemExit_Click(object sender, EventArgs e)
        {
            System.Windows.Application.Current.Shutdown();
        }


        private void MyNotifyIcon_MouseClick(object sender, System.Windows.Forms.MouseEventArgs e)
        {
            switch (e.Button)
            {
                case MouseButtons.Left:
                    ToggleMainWindow();
                    break;
                case MouseButtons.Right:
                    break;
            }
        }
        private void ToggleMainWindow()
        {
            if (window.WindowState == WindowState.Minimized)
            {
                window.WindowState = WindowState.Normal;
                window.ShowInTaskbar = true;
            }
            else
            {
                window.WindowState = WindowState.Minimized;
                window.ShowInTaskbar = false;
            }
        }
    }
}
