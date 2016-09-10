import Foundation
import ExpressiveCollections
import ExpressiveCasting

public class OptionRegistry : NSObject {
    private var types = [OptionType]()
    private var typesByName = [String: OptionType]()

    public override init() {
        super.init()
    }

    public func addOptionType(type: OptionType) {
        types <<< type
        typesByName[type.name] = type
    }

    public func parseOptionSpec(spec: [String: AnyObject], errorSink: LRManifestErrorSink) -> OptionSpec? {
        let typeName: String? = spec["type"]~~~
        if let typeName = typeName {
            if let type = typesByName[typeName] {
                return type.parse(spec, errorSink)
            } else {
                errorSink.addErrorMessage("Unknown option type '\(typeName)'")
                return nil
            }
        } else {
            errorSink.addErrorMessage("Missing option type")
            return nil
        }
    }
}
