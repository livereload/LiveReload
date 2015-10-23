import Cocoa
import ExpressiveFoundation
import LRProjectKit

var sharedWorkspace: Workspace!

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    private var o = [ListenerType]()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        sharedWorkspace = Workspace()

        o += sharedWorkspace.plugins.subscribe(self, AppDelegate.didDetectInvalidPlugins)
        setupPluginFolders()
        sharedWorkspace.plugins.update(.Initial)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        sharedWorkspace.dispose()
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

        sharedWorkspace.plugins.pluginContainerURLs = [bundledPluginsFolder]
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
