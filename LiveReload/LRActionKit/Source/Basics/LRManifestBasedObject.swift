import Foundation

public class LRManifestBasedObject : NSObject, LRManifestErrorSink {

    public let manifest: [String: AnyObject]

    private weak var errorSink: LRManifestErrorSink?

    public var errors: [NSError] = []

    public init(manifest: [String: AnyObject], errorSink: LRManifestErrorSink?) {
        self.errorSink = errorSink
        self.manifest = manifest
        super.init()
    }

    public func addErrorMessage(message: String) {
        let fullMessage = "\(message) in \(self.dynamicType) \(manifest)"

        errors.append(NSError(domain: ActionKitErrorDomain, code: ActionKitErrorCode.InvalidManifest.rawValue, userInfo: [NSLocalizedDescriptionKey: fullMessage]))

        if let es = errorSink {
            es.addErrorMessage(message)
        }
    }

    public var valid: Bool {
        return errors.isEmpty
    }

}
