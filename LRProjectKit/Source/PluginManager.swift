import Foundation
import AppKit
import LRCommons
import LRActionKit
import ExpressiveCollections

public class PluginManager : NSObject {

    public let context: PluginContext

    public init(context: PluginContext) {
        self.context = context
    }

    public func reloadPlugins() {
        actionsIndex.removeAll()
        _plugins = []

        let libraryFolderPaths = ["~/Library/LiveReload", "~/Dropbox/Library/LiveReload"]
        for libraryFolderPath in libraryFolderPaths {
            let pluginsFolder = libraryFolderPath.stringByAppendingPathComponent("Plugins").stringByExpandingTildeInPath
            loadPluginsFromFolder(pluginsFolder)
        }

        var bundledPluginsFolder = NSBundle.mainBundle().resourcePath!
        if let pluginsOverrideFolder = NSProcessInfo.processInfo().environment["LRBundledPluginsOverride"] as? NSString {
            let trimmed = pluginsOverrideFolder.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if !trimmed.isEmpty {
                bundledPluginsFolder = trimmed.stringByExpandingTildeInPath
            }
        }
        loadPluginsFromFolder(bundledPluginsFolder)

        for plugin in _plugins {
            for action in plugin.actions as! [Action] {
                addAction(action)
            }
        }

        let badPlugins = _plugins.filter { !$0.errors.isEmpty }
        if !badPlugins.isEmpty {
            var errorMessage = ""
            errorMessage += "Number of plugins with errors: \(badPlugins.count)\n\n"
            for plugin in badPlugins {
                errorMessage += "Error messages for \(plugin.path.lastPathComponent):\n"
                for error in plugin.errors as! [NSError] {
                    errorMessage += "• \(error.localizedDescription)\n"
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

        pluginsLoaded = true
    }

    public private(set) var plugins: [Plugin] {
        assert(pluginsLoaded, "Plugins not loaded yet")
        return _plugins
    }
    private var _plugins: [Plugin] = []

    public var userPluginNames: [String] {
        return [String](loadedPluginNames.keys)
    }

    public var actions: [Action] {
        return actionsIndex.list
    }

    public func compilerForExtension(ext: String) -> Compiler? {
        return compilers.find { $0.usesExtension(ext) }
    }

    public func compilerWithUniqueId(uniqueId: String) -> Compiler? {
        return compilers.find { $0.uniqueId == uniqueId }
    }

    public func actionWithIdentifier(identifier: String) -> Action? {
        return actionsIndex[identifier]
    }

    // private

    private var loadedPluginNames : Dictionary<String, Plugin> = [:]
    private var pluginsLoaded = false
    private var actionsIndex = IndexedArray<String, Action>() { $0.identifier }

    private func loadPluginFromFolder(pluginFolder: String) {
        let name = pluginFolder.lastPathComponent.stringByDeletingPathExtension
        if loadedPluginNames[name] == nil {
//            let plugin = Plugin(path: pluginFolder, )
            let plugin = Plugin(folderURL: <#T##NSURL#>, context: <#T##PluginContext#>))
            _loadedPluginNames[name] = plugin
            _plugins.append(plugin)
        }
    }

    private func loadPluginsFromFolder(pluginsFolder: String) {
        if let fileNames = NSFileManager.defaultManager().contentsOfDirectoryAtPath(pluginsFolder, error: nil) as! [String]? {
            for fileName in fileNames {
                if fileName.pathExtension == "lrplugin" {
                    _loadPluginFromFolder(pluginsFolder.stringByAppendingPathComponent(fileName))
                }
            }
        }
    }

    private func addAction(action: Action) {
        let identifier = action.identifier
        if action.valid {
            actionsIndex.append(action)
        } else {
            NSLog("Skipped invalid rule type def: \(identifier)")
        }
    }
    
}
