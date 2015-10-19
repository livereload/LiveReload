import Foundation
import LRActionKit
import PackageManagerKit
import ExpressiveCasting
import ExpressiveFoundation

public enum PluginEnvError: ErrorType {

    case MissingManifest
    case InvalidManifest(details: String)

}


public class Plugin: LRManifestErrorSink, ActionContainer {

    public let context: PluginContext

    public let folderURL: NSURL
    public let manifestURL: NSURL

    public let log: EnvLog

    public private(set) var actions: [Action]

    public private(set) var bundledPackageContainers: [LRPackageContainer]

    private var manifest: JSONObject

    public init(folderURL: NSURL, context: PluginContext) {
        self.folderURL = folderURL
        self.context = context
        manifestURL = folderURL.URLByAppendingPathComponent("manifest.json")
    }

    public var substitutionValues: [String: String] {
        return ["plugin": folderURL.path]
    }

    public func update() {
        let lb = log.beginUpdating()

        do {
            manifest = try loadManifest()
        } catch (let e) {
            lb.addError(e)
            manifest = [:]
        }

        loadActions()
        loadBundledPackageContainers()
    }

    private func loadManifest() throws {
        if !manifestURL.checkResourceIsReachableAndReturnError(nil) {
            throw PluginEnvError.MissingManifest
        }

        do {
            let obj = try NSJSONSerialization.JSONObjectWithContentsOfURL(manifestURL)
        } catch let e {
            throw PluginEnvError.InvalidManifest(details: String(e))
        }

        guard let manifest = JSONObjectValue(obj) else {
            throw PluginEnvError.InvalidManifest(details: "top-level JSON element is not an object")
        }
    }

    private func loadActions() {
        let submf: [JSONObject] = manifest["actions"]~~~ ?? []
        actions = submf.mapIf { Action(manifest: $0, container: self) }
    }

    private func loadBundledPackageContainers() {
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
