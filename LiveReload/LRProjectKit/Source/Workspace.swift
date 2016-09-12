import Foundation
import PackageManagerKit
import LRActionKit
import Uniflow

public class Workspace: PluginContext {
    
    public let bus: Bus

    public let log = EnvLog(origin: "")

    public let packageManager: LRPackageManager

    public let plugins: PluginManager

    public let rubies: RubyRuntimeRepository

    public let projects: ProjectListController

    private var disposed = false

    public init(bus: Bus) {
        self.bus = bus

        packageManager = LRPackageManager()
        packageManager.addPackageType(GemPackageType())
        packageManager.addPackageType(NpmPackageType())

        let pc = PluginContextImpl(packageManager: packageManager)
        plugins = PluginManager(context: pc)

        rubies = RubyRuntimeRepository()

        projects = ProjectListController(bus: bus)

        let lb = log.beginUpdating()
        lb.addChild(plugins.log)
        lb.commit()

        _processing.add(plugins.updating)
    }

    public func dispose() {
        disposed = true
        plugins.dispose()
    }

    public var processing: Processable {
        return _processing
    }

    private let _processing = ProcessingGroup()

}

private struct PluginContextImpl: PluginContext {

    let packageManager: LRPackageManager

}
