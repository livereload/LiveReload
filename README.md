LiveReload (paid GUI version)
=============================

Project Structure
-----------------


External libs:

* /Shared/libwebsockets
* /Shared/jansson


Cross-platform code (can of course use #ifdef to handle OS differences):

* /Shared/monitoring/fstree.{h,c} - fstree_t, port of FSTree
* /Shared/monitoring/fstreediffer.{h,c} - optional, may be merged with fsmonitor
* /Shared/monitoring/fsmonitor.{h,c} - fsmonitor_t, port of FSTree

* /Shared/model/project.{h,c} - project_t
* /Shared/model/model.{h,c} - project list; save/load code; port of Workspace.m; contains: model_init (loads the model from file), model_project_count(), model_project_at(index); .c listens for model change events and handles saving

* /Shared/app/communication.{h,c} -- handles web socket communcation; a merge of WebSocketServer.m and CommunicationController.m (we no longer need an OO wrapper around libwebsockets, so can simply use libwebsockets directly)


Windows-specific:

/Windows/app/main.c -- WinMain
/Windows/ui/trayitem.{h,c} -- port of StatusItemController + StatusItemView
/Windows/ui/mainwindow.{h,c} -- main_window_init(), main_window_toggle(), etc; MainWindowProc and all window handling code


Functions required by cross-platform code with highly OS-specific implementations:

* /Shared/app/osdep.h
* /Windows/app/osdep.c
* /Mac/app/osdep.m

Functions we need in osdep: preferences API (NSUserDefaults on OS X, registry on Windows), osdep_model_json_file_path()



Old Shit
--------


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


AppNewsKit
==========

* Collect usage statistics
* Deliver news to your users

Example ping.txt:

    {
        "see_explanation_at": "http://help.livereload.com/kb/about-us/usage-statistics-privacy-policy",
        "messages": [
            {
                "title": "MyApp on the Mac App Store!",
                "message": "MyApp 2.1 has been released on the Mac App Store, and is on sale (50% off)! Do you want to learn more about it?",
                "id": "myapp-2.0.0-release",
                "version": [">=2.0 <3.0"],
                "status": ["unregistered"],
                "stats": {
                    "stat.reloads": { "min": 10 }
                },
                "delay_if_nagged_within": "3d",
                "remind_later_in": "5d",
                "deliver_after": "2011-12-08 16:33:00",
                "wait_until_good_time": true,
                "delivery_on_stats": {
                    "or": {
                        "stat.reloads.last": { "within": 30 },
                        "stat.launch.first": { "within": 120 }
                    }
                },
                "random_percentage": 50,
                "primary_button_url": "http://myapp.com/mas/",
                "primary_button_title": "Visit Mac App Store"
            }
        ]
    }
