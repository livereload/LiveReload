import Cocoa
import Uniflow
import LRProjectKit
import LRActionKit
import ExpressiveFoundation

let bus = Bus()
let workspace = Workspace(bus: bus)
private var o = Observation()

extension LiveReloadAppDelegate {
    
    func initializeSwiftPartsOfApp() {
        o += workspace.plugins.subscribe(self, LiveReloadAppDelegate.didDetectInvalidPlugins)
        setupPluginFolders()
        ActionKitSingleton.sharedActionKit.packageManager = workspace.packageManager
        workspace.plugins.update(.Initial)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationWillTerminate), name: NSApplicationWillTerminateNotification, object: nil)
    }
    
    @objc private func swiftApplicationWillTerminate(aNotification: NSNotification) {
        workspace.dispose()
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
        
        workspace.plugins.pluginContainerURLs = [bundledPluginsFolder]
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
