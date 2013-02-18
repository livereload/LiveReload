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
        private NotifyIcon myNotifyIcon;
        private ContextMenu contextMenuTray = new ContextMenu();

        public event Action MainWindowHideEvent;
        public event Action MainWindowShowEvent;
        public event Action MainWindowToggleEvent;

        public TrayIconController()
        {
            MenuItem menuItemShow = new MenuItem("&Show LiveReload");
            menuItemShow.DefaultItem = true;
            MenuItem menuItemExit = new MenuItem("E&xit");

            menuItemShow.Click += new EventHandler(menuItemShow_Click);
            menuItemExit.Click += new EventHandler(menuItemExit_Click);

            contextMenuTray.MenuItems.Add(menuItemShow);
            contextMenuTray.MenuItems.Add(menuItemExit);

            Uri iconUri = new Uri("pack://application:,,,/img/LiveReload.ico", UriKind.RelativeOrAbsolute);
            System.IO.Stream iconStream = System.Windows.Application.GetResourceStream(iconUri).Stream;

            //NotifyIcon icon = new NotifyIcon();

            myNotifyIcon = new NotifyIcon();
            myNotifyIcon.Icon = new Icon(iconStream);
            myNotifyIcon.MouseClick += new MouseEventHandler(MyNotifyIcon_MouseClick);
            myNotifyIcon.ContextMenu = contextMenuTray;
            myNotifyIcon.Visible = true;
        }

        public void Dispose()
        {
            myNotifyIcon.Dispose();
        }
        private void menuItemShow_Click(object sender, EventArgs e)
        {
            MainWindowShowEvent();
        }

        private void menuItemExit_Click(object sender, EventArgs e)
        {
            System.Windows.Application.Current.Shutdown();
        }

        private void MyNotifyIcon_MouseClick(object sender, MouseEventArgs e)
        {
            switch (e.Button)
            {
                case MouseButtons.Left:
                    MainWindowToggleEvent();
                    break;
                case MouseButtons.Right:
                    break;
            }
        }
    }
}
