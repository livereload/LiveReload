import Foundation
import LRActionKit
import PackageManagerKit
import ExpressiveCasting
import ExpressiveFoundation

public enum PluginEnvError: ErrorType {

    case MissingManifest
    case InvalidManifest(details: String)

}


public class Plugin: ActionContainer, EmitterType, Updatable {
    public var _listeners = EventListenerStorage()

    public let context: PluginContext

    public let name: String
    public let folderURL: NSURL
    public let manifestURL: NSURL

    public let log: EnvLog

    public private(set) var actions: [Action] = []

    public private(set) var bundledPackageContainers: [LRPackageContainer] = []

    public init(folderURL: NSURL, context: PluginContext) {
        self.folderURL = folderURL
        self.context = context
        manifestURL = folderURL.URLByAppendingPathComponent("manifest.json")
        log = EnvLog(origin: "\(folderURL.lastPathComponent!)")
        name = folderURL.URLByDeletingPathExtension!.lastPathComponent!

        updating = UpdateBehavior(self, Plugin.performUpdate)
    }

    private var updating: UpdateBehavior<Plugin, StdUpdateReason>!

    public var isUpdating: Bool {
        return updating.isUpdating
    }

    public func update(reason: StdUpdateReason) {
        updating.update(reason)
    }

    public var substitutionValues: [String: String] {
        return ["plugin": folderURL.path!]
    }

    private func performUpdate() {
        let lb = log.beginUpdating()

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            let manifest: JSONObject
            do {
                manifest = try self.loadManifestInBackground()
            } catch (let e) {
                lb.addError(e)
                manifest = [:]
            }

            dispatch_async(dispatch_get_main_queue()) {
                self.loadActions(manifest)
                self.loadBundledPackageContainers(manifest)

                self.updating.didSucceed()
            }
        }
    }

    private func loadManifestInBackground() throws -> JSONObject {
        if !manifestURL.checkResourceIsReachableAndReturnError(nil) {
            throw PluginEnvError.MissingManifest
        }

        let obj: AnyObject
        do {
            obj = try NSJSONSerialization.JSONObjectWithContentsOfURL(manifestURL)
        } catch let e {
            throw PluginEnvError.InvalidManifest(details: String(e))
        }

        guard let manifest = JSONObjectValue(obj) else {
            throw PluginEnvError.InvalidManifest(details: "top-level JSON element is not an object")
        }
        return manifest
    }

    private func loadActions(manifest: JSONObject) {
        let submf: [JSONObject] = manifest["actions"]~~~ ?? []
        actions = submf.mapIf { Action(manifest: $0, container: self) }
    }

    private func loadBundledPackageContainers(manifest: JSONObject) {
        for pc in bundledPackageContainers {
            pc.packageType.removePackageContainer(pc)
        }
        bundledPackageContainers = context.packageManager.packageTypes.mapIf(self.loadBundledPackageContainersForType)
        for pc in bundledPackageContainers {
            pc.packageType.addPackageContainer(pc)
        }
    }

    private func loadBundledPackageContainersForType(packageType: LRPackageType) -> LRPackageContainer? {
        guard let bundledPackagesFolderName = packageType.bundledPackagesFolderName else {
            return nil
        }

        let bundledPackagesURL = folderURL.URLByAppendingPathComponent(bundledPackagesFolderName)
        guard bundledPackagesURL.checkIsAccessibleDirectory() else {
            return nil
        }

        let container = packageType.packageContainerAtFolderURL(bundledPackagesURL)
        container.containerType = .Bundled
        return container
    }

}
