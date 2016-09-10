import Foundation
import ExpressiveCocoa
import ExpressiveCasting

public class TextOptionType : OptionType {
    public override var name: String {
        return "text-field"
    }

    public override func parse(manifest: [String: AnyObject], _ errorSink: LRManifestErrorSink) -> OptionSpec? {
        let spec = TextOptionSpec()
        if !parse(into: spec, manifest, errorSink) {
            return nil
        }
        if !spec.validate(errorSink) {
            return nil
        }
        return spec
    }

    internal func parse(into spec: TextOptionSpec, _ manifest: [String: AnyObject], _ errorSink: LRManifestErrorSink) -> Bool {
        if !parseCommon(into: spec, manifest, errorSink) {
            return false
        }
        spec.arguments = P2ParseCommandLineSpec(manifest["args"]) 
        spec.placeholder = manifest["placeholder"]~~~
        spec.skipArgumentsIfEmpty = manifest["skip-if-empty"]~~~ ?? true
        return true
    }
}

internal class TextOptionSpec : OptionSpec {
    var placeholder: String?
    var arguments: [String] = []
    var skipArgumentsIfEmpty = true

    override func validate(errorSink: LRManifestErrorSink) -> Bool {
        if !super.validate(errorSink) {
            return false
        }
        if label == nil {
            errorSink.addErrorMessage("Missing label")
            return false
        }
        return true
    }

    internal override func newOption(rule rule: Rule) -> Option {
        return TextOption(rule: rule, spec: self)
    }
}

public class TextOption : Option, TextOptionProtocol {

    public let label: String
    public let placeholder: String?
    public let arguments: [String]
    public let skipArgumentsIfEmpty: Bool

    private init(rule: Rule, spec: TextOptionSpec) {
        label = spec.label!
        placeholder = spec.placeholder
        arguments = spec.arguments
        skipArgumentsIfEmpty = spec.skipArgumentsIfEmpty
        super.init(rule: rule, identifier: spec.identifier!)
    }

    public var defaultValue: String {
        return ""
    }

    public var modelValue: String? {
        get {
            return rule.optionValueForKey(identifier)~~~
        }
        set {
            rule.setOptionValue(newValue, forKey: identifier)
        }
    }

    public var effectiveValue: String {
        get {
            return modelValue ?? defaultValue
        }
        set {
            if newValue == defaultValue {
                modelValue = nil
            } else {
                modelValue = newValue
            }
        }
    }

    public override var commandLineArguments: [String] {
        let value = effectiveValue
        if value.isEmpty && skipArgumentsIfEmpty {
            return []
        }
        return arguments.substituteValues(["$(value)": value])
    }

}

