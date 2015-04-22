import Foundation
import SwiftyFoundation
import PackageManagerKit

public class LRAssetPackageConfiguration: LRManifestBasedObject {
    
    public let packageReferences: [LRPackageReference]

    public override init(manifest: [NSObject: AnyObject], errorSink: LRManifestErrorSink) {
        let packageManager = ActionKitSingleton.sharedActionKit().packageManager

        let strings = ArrayValue(manifest["packages"], { $0 as? String }) ?? []

        packageReferences = mapIf(strings) { packageManager.packageReferenceWithString($0) }

        super.init(manifest: manifest, errorSink: errorSink)

        if strings.isEmpty {
            addErrorMessage("No packages defined in a package configuration")
        }
    }
    
}
