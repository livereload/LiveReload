import Foundation
import ExpressiveFoundation
import LRActionKit
import ATPathSpec
import ExpressiveCollections
import PromiseKit

public class PluginManager: StdEmitterType {

    public struct DidDetectInvalidPlugins: EventType {
        public let invalidPlugins: [Plugin]
    }

    public let context: PluginContext

    public let log = EnvLog(origin: "Plugin Manager")

    public var pluginContainerURLs: [NSURL] = []

    public init(context: PluginContext) {
        self.context = context

        _listUpdating.initializeWithHost(self, emitsEventsOnHost: false, performs: PluginManager.reloadPlugins)
        _updating.initializeWithHost(self, emitsEventsOnHost: true)
        _updating.add(_listUpdating)
        _updating.add(self, method: PluginManager.getUpdatableChildren)
    }

    public func dispose() {
        _updating.dispose()
        _listUpdating.dispose()

        for plugin in plugins {
            plugin.dispose()
        }
        plugins = []
    }

    public var updating: Processable {
        return _updating
    }

    public func update(reason: StdUpdateReason) {
        _listUpdating.schedule(reason)
    }

    private func reloadPlugins(reason: StdUpdateReason, context: OperationContext) -> Promise<Void> {
        let (promise, fulfill, _) = Promise<Void>.pendingPromise()

        // TODO: update incrementally

        actionsIndex.removeAll()
        for plugin in plugins {
            plugin.dispose()
        }
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

        _updating.refreshChildren()
        fulfill()

        return promise
    }

    public private(set) var plugins: [Plugin] = []

    private func getUpdatableChildren() -> [Processable] {
        return plugins.map { $0.updating }
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

    private var _listUpdating = ProcessorImpl<StdUpdateReason>()
    private var _updating = ProcessingGroup()

    public var _listeners = EventListenerStorage()

}
