import Foundation
import PackageManagerKit
import LRActionKit
import PromiseKit

public class Workspace: PluginContext {

    public let log = EnvLog(origin: "")

    public let packageManager: LRPackageManager

    public let plugins: PluginManager

    public let rubies: RubyRuntimeRepository

    private var disposed = false

    public init() {
        packageManager = LRPackageManager()
        packageManager.addPackageType(GemPackageType())
        packageManager.addPackageType(NpmPackageType())

        let pc = PluginContextImpl(packageManager: packageManager)
        plugins = PluginManager(context: pc)

        rubies = RubyRuntimeRepository()

        let lb = log.beginUpdating()
        lb.addChild(plugins.log)
        lb.commit()
    }

    public func dispose() {
        if !disposed {
            disposed = true

            // TODO: clear everything
        }
    }

}

private struct PluginContextImpl: PluginContext {

    let packageManager: LRPackageManager

}
