import Foundation
import ExpressiveCasting

public class OptionType : NSObject {
    public var name: String {
        fatalError("must override")
    }

    public func parse(manifest: [String: AnyObject], _ errorSink: LRManifestErrorSink) -> OptionSpec? {
        fatalError("must override")
    }

    internal func parseCommon(into spec: OptionSpec, _ manifest: [String: AnyObject], _ errorSink: LRManifestErrorSink) -> Bool {
        spec.identifier = manifest["id"]~~~
        spec.label = manifest["label"]~~~
        return true
    }

}

public class OptionSpec : NSObject {
    var identifier: String?
    var label: String?

    func validate(errorSink: LRManifestErrorSink) -> Bool {
        if identifier == nil {
            errorSink.addErrorMessage("Missing id key")
            return false
        }
        return true
    }

    public func newOption(rule rule: Rule) -> Option {
        fatalError("must override")
    }
}

public class Option : NSObject, OptionProtocol {

    public let identifier: String
    public let rule: Rule

    internal /*protected*/ init(rule: Rule, identifier: String) {
        self.identifier = identifier
        self.rule = rule
    }

    public var commandLineArguments: [String] {
        return []
    }

}
