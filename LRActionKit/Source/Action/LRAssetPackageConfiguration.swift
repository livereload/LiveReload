import Foundation
import ExpressiveCasting
import PackageManagerKit

public class LRAssetPackageConfiguration: LRManifestBasedObject {
    
    public let packageReferences: [LRPackageReference]

    public override init(manifest: [String: AnyObject], errorSink: LRManifestErrorSink?) {
        let packageManager = ActionKitSingleton.sharedActionKit.packageManager

        let strings = ArrayValue(manifest["packages"]) { $0 as? String } ?? []
        packageReferences = strings.mapIf { packageManager.packageReferenceWithString($0) }

        super.init(manifest: manifest, errorSink: errorSink)

        if strings.isEmpty {
            addErrorMessage("No packages defined in a package configuration")
        }
    }
    
}
