
import Foundation
import AppKit

let g_sharedPluginManager = PluginManager()

class PluginManager : NSObject {

    class func sharedPluginManager() -> PluginManager {
        return g_sharedPluginManager
    }

    func reloadPlugins() {
        _actionTypes.removeAll()
        _plugins = []

        let libraryFolderPaths = ["~/Library/LiveReload", "~/Dropbox/Library/LiveReload"]
        for libraryFolderPath in libraryFolderPaths {
            let pluginsFolder = libraryFolderPath.stringByAppendingPathComponent("Plugins").stringByExpandingTildeInPath
            _loadPluginsFromFolder(pluginsFolder)
        }

        var bundledPluginsFolder = NSBundle.mainBundle().resourcePath!
        if let pluginsOverrideFolder = NSProcessInfo.processInfo().environment["LRBundledPluginsOverride"] as? String {
            let trimmed = pluginsOverrideFolder.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if !trimmed.isEmpty {
                bundledPluginsFolder = trimmed.stringByExpandingTildeInPath
            }
        }
        _loadPluginsFromFolder(bundledPluginsFolder)

        for plugin in _plugins {
            for actionType in plugin.actionTypes as ActionType[] {
                _addActionType(actionType)
            }
        }

        let badPlugins = _plugins.filter { !$0.errors.isEmpty }
        if !badPlugins.isEmpty {
            var errorMessage = ""
            errorMessage += "Number of plugins with errors: \(badPlugins.count)\n\n"
            for plugin in badPlugins {
                errorMessage += "Error messages for \(plugin.path.lastPathComponent):\n"
                for error in plugin.errors as NSError[] {
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

        _pluginsLoaded = true
    }

    var plugins: Plugin[] {
        assert(_pluginsLoaded, "Plugins not loaded yet")
        return _plugins
    }

    var _plugins: Plugin[] = []

    var compilers: Compiler[] {
        return flatten(_plugins.map { $0.compilers as Compiler[] })
    }

    var compilerSourceExtensions: String[] {
        let compiler = Compiler()
        return flatten(compilers.map { $0.extensions as String[] })
    }

    var userPluginNames: String[] {
        return String[](_loadedPluginNames.keys)
    }

    var actionTypes: ActionType[] {
        return _actionTypes.list
    }

    func compilerForExtension(ext: String) -> Compiler? {
        return findIf(compilers) { $0.usesExtension(ext) }
    }

    func compilerWithUniqueId(uniqueId: String) -> Compiler? {
        return findIf(compilers) { $0.uniqueId == uniqueId }
    }

    func actionTypeWithIdentifier(identifier: String) -> ActionType? {
        return _actionTypes[identifier]
    }

// private

    var _loadedPluginNames : Dictionary<String, Plugin> = [:]
    var _pluginsLoaded = false
    var _actionTypes = IndexedArray<String, ActionType>() { $0.identifier }

    func _loadPluginFromFolder(pluginFolder: String) {
        let name = pluginFolder.lastPathComponent.stringByDeletingPathExtension
        if !_loadedPluginNames[name] {
            let plugin = Plugin(path: pluginFolder)
            _loadedPluginNames[name] = plugin
            _plugins.append(plugin)
        }
    }

    func _loadPluginsFromFolder(pluginsFolder: String) {
        if let fileNames = NSFileManager.defaultManager().contentsOfDirectoryAtPath(pluginsFolder, error: nil) as String[]? {
            for fileName in fileNames {
                if fileName.pathExtension == "lrplugin" {
                    _loadPluginFromFolder(pluginsFolder.stringByAppendingPathComponent(fileName))
                }
            }
        }
    }

    func _addActionType(actionType: ActionType) {
        let identifier = actionType.identifier
        if actionType.valid {
            _actionTypes.append(actionType)
        } else {
            NSLog("Skipped invalid rule type def: \(identifier)")
        }
    }

}
