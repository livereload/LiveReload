using System;
using System.Windows.Forms;
using System.Drawing;


namespace LiveReload
{
    class TrayIconController
    {
        private NotifyIcon myNotifyIcon;
        private ContextMenu contextMenuTray = new ContextMenu();

        //public event Action MainWindowHideEvent;
        public event Action MainWindowShowEvent;
        public event Action MainWindowToggleEvent;

        public TrayIconController() {
            var menuItemShow = new MenuItem("&Show LiveReload");
            menuItemShow.DefaultItem = true;
            var menuItemExit = new MenuItem("E&xit");

            menuItemShow.Click += menuItemShow_Click;
            menuItemExit.Click += menuItemExit_Click;

            contextMenuTray.MenuItems.Add(menuItemShow);
            contextMenuTray.MenuItems.Add(menuItemExit);

            var iconUri = new Uri("pack://application:,,,/img/LiveReload.ico", UriKind.RelativeOrAbsolute);
            System.IO.Stream iconStream = System.Windows.Application.GetResourceStream(iconUri).Stream;

            //NotifyIcon icon = new NotifyIcon();

            myNotifyIcon = new NotifyIcon();
            myNotifyIcon.Icon = new Icon(iconStream);
            myNotifyIcon.MouseClick += MyNotifyIcon_MouseClick;
            myNotifyIcon.ContextMenu = contextMenuTray;
            myNotifyIcon.Visible = true;
        }

        public void Dispose() {
            myNotifyIcon.Dispose();
        }
        private void menuItemShow_Click(object sender, EventArgs e) {
            MainWindowShowEvent();
        }

        private void menuItemExit_Click(object sender, EventArgs e) {
            System.Windows.Application.Current.Shutdown();
        }

        private void MyNotifyIcon_MouseClick(object sender, MouseEventArgs e) {
            switch (e.Button) {
                case MouseButtons.Left:
                    MainWindowToggleEvent();
                    break;
                case MouseButtons.Right:
                    break;
            }
        }
    }
}
