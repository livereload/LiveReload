import Cocoa
import ExpressiveFoundation
import LRProjectKit
import LRAbstractModel

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    private var o = Observation()

    var app: App!
    var appController: AppController!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        app = App()
        appController = AppController(app: app)

        o += app.workspace.plugins.subscribe(self, AppDelegate.didDetectInvalidPlugins)
        setupPluginFolders()
        app.workspace.plugins.update(.Initial)

        appController.showMainWindow()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        app.dispose()
    }

    private func setupPluginFolders() {
        var bundledPluginsFolder = NSBundle.mainBundle().resourceURL!
        if let pluginsOverrideFolder = NSProcessInfo.processInfo().environment["LRBundledPluginsOverride"] {
            let trimmed = pluginsOverrideFolder.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if !trimmed.isEmpty {
                bundledPluginsFolder = NSURL(fileURLWithPath: (trimmed as NSString).stringByExpandingTildeInPath)
            }
        }

#if false
        let libraryFolderPaths = ["~/Library/LiveReload", "~/Dropbox/Library/LiveReload"]
        for libraryFolderPath in libraryFolderPaths {

            let pluginsFolder = libraryFolderPath.stringByAppendingPathComponent("Plugins").stringByExpandingTildeInPath
            loadPluginsFromFolder(pluginsFolder)
        }
#endif

        app.workspace.plugins.pluginContainerURLs = [bundledPluginsFolder]
    }

    func didDetectInvalidPlugins(event: PluginManager.DidDetectInvalidPlugins) {
        var errorMessage = ""
        errorMessage += "Number of plugins with errors: \(event.invalidPlugins.count)\n\n"
        for plugin in event.invalidPlugins {
            errorMessage += "Error messages for \(plugin.folderURL.lastPathComponent!):\n"
            for error in plugin.log.errors {
                errorMessage += "• \(error)\n"
            }
        }

        NSLog("%@", errorMessage)
        let alert = NSAlert()
        alert.messageText = "LiveReload couldn't load some plugins"
        alert.informativeText = errorMessage
        alert.addButtonWithTitle("Continue")
        alert.addButtonWithTitle("Quit")
        if alert.runModal() == NSAlertSecondButtonReturn {
            exit(1);
        }
    }

}
