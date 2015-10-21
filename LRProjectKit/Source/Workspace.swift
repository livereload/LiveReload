import Foundation
import PackageManagerKit

public class Workspace: PluginContext {

    public let packageManager: LRPackageManager

    public let plugins: PluginManager

    public init() {
        packageManager = LRPackageManager()
        packageManager.addPackageType(GemPackageType())
        packageManager.addPackageType(NpmPackageType())

        let pc = PluginContextImpl(packageManager: packageManager)
        plugins = PluginManager(context: pc)
    }

}

private struct PluginContextImpl: PluginContext {

    let packageManager: LRPackageManager

}
