import Foundation
import SwiftyFoundation
import LRCommons
import PackageManagerKit

public class LRManifestLayer: LRManifestBasedObject {

    // parsed by the layers to seed the package version detection system
    public let packageReferences: [LRPackageReference]

    public convenience override init(manifest: [String: AnyObject], errorSink: LRManifestErrorSink?) {
        let packageManager = ActionKitSingleton.sharedActionKit().packageManager;

        let dicts = ArrayValue(manifest["applies_to"], { $0 as? [String: AnyObject] }) ?? []
        let packageReferences = mapIf(dicts) { packageManager.packageReferenceWithDictionary($0) }

        self.init(manifest: manifest, requiredPackageReferences: packageReferences, errorSink: errorSink)
    }

    public init(manifest: [String: AnyObject], requiredPackageReferences: [LRPackageReference], errorSink: LRManifestErrorSink?) {
        self.packageReferences = requiredPackageReferences
        super.init(manifest: manifest, errorSink: errorSink)
    }

}
