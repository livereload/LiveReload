import Foundation
import PackageManagerKit
import PiiVersionKit
import LRCommons

public class LRActionVersion: NSObject {

    public var action: Action
    public var manifest: LRActionManifest
    public var packageSet: LRPackageSet

    public init(action: Action, manifest: LRActionManifest, packageSet: LRPackageSet) {
        self.action = action
        self.manifest = manifest
        self.packageSet = packageSet
        super.init()

        if packageSet.packages.isEmpty {
            fatalError("LRActionVersion.init with an empty packageSet")
        }
    }

    public var primaryVersion: LRVersion {
        let packages = packageSet.packages as! [LRPackage]
        return packages[0].version
    }

    public override var description: String {
        return primaryVersion.description
    }

}
