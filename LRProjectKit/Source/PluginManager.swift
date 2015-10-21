import Foundation
import AppKit
import LRActionKit
import ATPathSpec
import ExpressiveCollections

public class PluginManager : NSObject {

    public let context: PluginContext

    public let log = EnvLog(origin: "Plugin Manager")

    public init(context: PluginContext) {
        self.context = context
    }

    public func reloadPlugins() {
        actionsIndex.removeAll()
        plugins = []

        let lb = log.beginUpdating()

//        let libraryFolderPaths = ["~/Library/LiveReload", "~/Dropbox/Library/LiveReload"]
//        for libraryFolderPath in libraryFolderPaths {
//
//            let pluginsFolder = libraryFolderPath.stringByAppendingPathComponent("Plugins").stringByExpandingTildeInPath
//            loadPluginsFromFolder(pluginsFolder)
//        }

        var bundledPluginsFolder = NSBundle.mainBundle().resourcePath!
        if let pluginsOverrideFolder = NSProcessInfo.processInfo().environment["LRBundledPluginsOverride"] {
            let trimmed = pluginsOverrideFolder.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if !trimmed.isEmpty {
                bundledPluginsFolder = (trimmed as NSString).stringByExpandingTildeInPath
            }
        }
        loadPluginsFromFolder(NSURL(fileURLWithPath: bundledPluginsFolder, isDirectory: true), logTo: lb)

        for plugin in plugins {
            for action in plugin.actions {
                addAction(action)
            }
        }

        let badPlugins = plugins.filter { $0.log.hasErrors }
        if !badPlugins.isEmpty {
            var errorMessage = ""
            errorMessage += "Number of plugins with errors: \(badPlugins.count)\n\n"
            for plugin in badPlugins {
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

    public private(set) var plugins: [Plugin] = []

    public var userPluginNames: [String] {
        return Array(pluginsByName.keys)
    }

    public var actions: [Action] {
        return actionsIndex.list
    }

    public func actionWithIdentifier(identifier: String) -> Action? {
        return actionsIndex[identifier]
    }


    private var pluginsByName : Dictionary<String, Plugin> = [:]
    private var actionsIndex = IndexedArray<String, Action>() { $0.identifier }

    private func loadPluginFromFolder(pluginFolderURL: NSURL, logTo lb: EnvLogBuilder) {
        let name = pluginFolderURL.URLByDeletingPathExtension!.lastPathComponent!
        if pluginsByName[name] == nil {
            let plugin = Plugin(folderURL: pluginFolderURL, context: context)
            pluginsByName[name] = plugin
            plugins.append(plugin)
            lb.addChild(plugin.log)
        } else {
            lb.addWarning("Skipped \(name)", ["at \(pluginFolderURL.path)"])
        }
    }

    private func loadPluginsFromFolder(pluginsFolderURL: NSURL, logTo lb: EnvLogBuilder) {
        let fm = NSFileManager.defaultManager()
        guard let itemURLs = try? fm.contentsOfDirectoryAtURL(pluginsFolderURL, includingPropertiesForKeys: nil, options: [.SkipsHiddenFiles]) else {
            return
        }

        for itemURL in itemURLs {
            if itemURL.pathExtension == "lrplugin" {
                loadPluginFromFolder(itemURL, logTo: lb)
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
