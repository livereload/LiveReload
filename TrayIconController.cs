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

        public TrayIconController(MainWindow window_)
        {
            window = window_;
            myNotifyIcon = new System.Windows.Forms.NotifyIcon();
            myNotifyIcon.Icon = new System.Drawing.Icon(@"img/LiveReload.ico");
            myNotifyIcon.MouseClick += new System.Windows.Forms.MouseEventHandler(MyNotifyIcon_MouseClick);
            myNotifyIcon.Visible = true;
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
