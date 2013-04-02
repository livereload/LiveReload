using System;
//using System.Collections.Generic;
//using System.Linq;
//using System.Text;

using System.Windows;
using System.Deployment.Application;

namespace LiveReload
{
    public partial class App : Application
    {
        public void InstallUpdateSyncWithInfo() {
            UpdateCheckInfo info = null;

            if (ApplicationDeployment.IsNetworkDeployed) {
                ApplicationDeployment ad = ApplicationDeployment.CurrentDeployment;

                try {
                    info = ad.CheckForDetailedUpdate();
                } catch (DeploymentDownloadException dde) {
                    MessageBox.Show("The new version of the application cannot be downloaded at this time. \n\nPlease check your network connection, or try again later. Error: " + dde.Message);
                    return;
                } catch (InvalidDeploymentException ide) {
                    MessageBox.Show("Cannot check for a new version of the application. The ClickOnce deployment is corrupt. Please redeploy the application and try again. Error: " + ide.Message);
                    return;
                } catch (InvalidOperationException ioe) {
                    MessageBox.Show("This application cannot be updated. It is likely not a ClickOnce application. Error: " + ioe.Message);
                    return;
                }

                if (!info.UpdateAvailable) {
                    MessageBox.Show("You have the latest version of the application.");
                    return;
                } else {
                    Boolean doUpdate = true;

                    if (!info.IsUpdateRequired) {
                        if (!(MessageBoxResult.OK == MessageBox.Show("An update is available. Would you like to update the application now?", "Update Available", MessageBoxButton.OKCancel))) {
                            doUpdate = false;
                        }
                    } else {
                        // Display a message that the app MUST reboot. Display the minimum required version.
                        MessageBox.Show("This application has detected a mandatory update from your current " +
                            "version to version " + info.MinimumRequiredVersion.ToString() +
                            ". The application will now install the update and restart.",
                            "Update Available", MessageBoxButton.OK,
                            MessageBoxImage.Information);
                    }

                    if (doUpdate) {
                        try {
                            ad.Update();
                            MessageBox.Show("The application has been upgraded, and will now restart.");
                            EntryPoint.isRestarting = true;
                            Application.Current.Shutdown();
                        } catch (DeploymentDownloadException dde) {
                            MessageBox.Show("Cannot install the latest version of the application. \n\nPlease check your network connection, or try again later. Error: " + dde);
                            return;
                        }
                    }
                }
            }
        }
    }
}
