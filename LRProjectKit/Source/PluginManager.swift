import Foundation
import ExpressiveFoundation
import LRActionKit
import ATPathSpec
import ExpressiveCollections

public class PluginManager: EmitterType {

    public var _listeners = EventListenerStorage()

    public struct DidDetectInvalidPlugins: EventType {
        public let invalidPlugins: [Plugin]
    }

    public let context: PluginContext

    public let log = EnvLog(origin: "Plugin Manager")

    public var pluginContainerURLs: [NSURL] = []

    public init(context: PluginContext) {
        self.context = context
        updating = UpdateBehavior(self, PluginManager.reloadPlugins, childrenMethod: PluginManager.getUpdatableChildren)
    }

    private var updating: UpdateBehavior<PluginManager, StdUpdateReason>!

    public var isUpdating: Bool {
        return updating.isUpdating
    }

    public func update(reason: StdUpdateReason) {
        updating.update(reason)
    }

    private func reloadPlugins() {
        actionsIndex.removeAll()
        plugins = []

        let lb = log.beginUpdating()

        for folder in pluginContainerURLs {
            loadPluginsFromFolder(folder, logTo: lb)
        }

        for plugin in plugins {
            for action in plugin.actions {
                addAction(action)
            }
        }

        let badPlugins = plugins.filter { $0.log.hasErrors }
        if !badPlugins.isEmpty {
            emit(DidDetectInvalidPlugins(invalidPlugins: badPlugins))
        }

        updating.didSucceed()
    }

    public private(set) var plugins: [Plugin] = []

    private func getUpdatableChildren() -> [Updatable] {
        return plugins.map { $0 as Updatable }
    }

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

            plugin.update(.Initial)
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
