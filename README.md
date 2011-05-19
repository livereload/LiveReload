LiveReload (paid GUI version)
=============================

Hunting down the crx file from Chrome Web Store:

* install the extension
* open `~/Library/Caches/Google/Chrome/Default/Cache`
* open a data file in TextMate
* search for `crx`
* download from the found URL, something like:

      https://clients2.googleusercontent.com/crx/download/OQAAAP7LEOajd1v0yz2cqUXd8G_fJDnxSckZ9aB21rIRYJtibrBHokesrCY3MzgSZW4SiJF5ZfqTntmn-0wiquEpTXUAxlKa5e3hCDew-eg9pnQm55agMKl4xEzW/extension_1_6.crx

Preferences store the model (=> synced between macs?)

  Repository

    startMonitoring -> [project startMonitoring]
    stopMonitoring  -> [project stopMonitoring]

    save

    Project <FSMonitorDelegate>: NSMutableSet *projects
      NSString *path
      BOOL refreshCSS
      BOOL refreshJS
      BOOL autoreload

      FSMonitor *monitor

      startMonitoring
      stopMonitoring

      FSMonitorDelegate change -> [ClientManager broadcastChangeEvent]

  FSMonitor
    NSString *path
  FSMonitorDelegate

  ProjectChangeEvent
    Project *project
    NSString *path

  WebSocketController
    WebSocketClient NSMutableArray *clients
      websocket connection info...

      sendChangeEvent:(ProjectChangeEvent *)event

      or maybe just a generic websocket client class? no need for a domain-specific wrapper?

    broadcastChangeEvent:(ProjectChangeEvent *)event

    first client connected   -> [Repository startMonitoring]
    last client disconnected -> [Repository stopMonitoring]

  StatusItemController
    -> start at login on/off (LoginItemController)
    -> add project (Project -> Repository)
    -> remove project (Repository)
    -> reconfigure project (Repository, Project)

  LoginItemController

  IntegrationController

    isSafariAvailable
    isSafariIntegrated
    integrateIntoSafari

    isChromeAvailable
    isChromeIntegrated
    integrateIntoChrome



Ideas:

  real iPhone-like popover UI

  "edit project" command to open the project in your fav editor

