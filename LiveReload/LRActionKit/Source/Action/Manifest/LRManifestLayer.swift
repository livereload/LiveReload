import Foundation
import ExpressiveCasting
import ExpressiveCollections
import PackageManagerKit

public class LRManifestLayer: LRManifestBasedObject {

    // parsed by the layers to seed the package version detection system
    public let packageReferences: [LRPackageReference]

    public convenience override init(manifest: [String: AnyObject], errorSink: LRManifestErrorSink?) {
        let packageManager = ActionKitSingleton.sharedActionKit.packageManager

        let dicts = JSONObjectsArrayValue(manifest["applies_to"]) ?? []
        let packageReferences = dicts.mapIf { packageManager.packageReferenceWithDictionary($0) }

        self.init(manifest: manifest, requiredPackageReferences: packageReferences, errorSink: errorSink)
    }

    public init(manifest: [String: AnyObject], requiredPackageReferences: [LRPackageReference], errorSink: LRManifestErrorSink?) {
        self.packageReferences = requiredPackageReferences
        super.init(manifest: manifest, errorSink: errorSink)
    }

}
