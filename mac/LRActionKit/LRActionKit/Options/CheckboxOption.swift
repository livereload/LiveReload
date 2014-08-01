import Foundation
import SwiftyFoundation
import LRCommons

public class CheckboxOptionType : OptionType {
    public override var name: String {
        return "checkbox"
    }

    public func parse(manifest: [String: AnyObject], errorSink: LRManifestErrorSink) -> OptionSpec? {
        var spec = CheckboxOptionSpec()
        if !parse(into: spec, manifest, errorSink) {
            return nil
        }
        if !spec.validate(errorSink) {
            return nil
        }
        return spec
    }

    internal func parse(into spec: CheckboxOptionSpec, _ manifest: [String: AnyObject], _ errorSink: LRManifestErrorSink) -> Bool {
        if !parseCommon(into: spec, manifest, errorSink) {
            return false
        }
        spec.argumentsWhenOn  = P2ParseCommandLineSpec(manifest["args"]) as [String]
        spec.argumentsWhenOff = P2ParseCommandLineSpec(manifest["args-off"]) as [String]
        return true
    }
}

internal class CheckboxOptionSpec : OptionSpec {
    var argumentsWhenOn:  [String] = []
    var argumentsWhenOff: [String] = []

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

    public override func newOption(#rule: Rule) -> Option {
        return CheckboxOption(rule: rule, spec: self)
    }
}

public class CheckboxOption : Option {

    let label: String
    let argumentsWhenOn: [String]
    let argumentsWhenOff: [String]

    private init(rule: Rule, spec: CheckboxOptionSpec) {
        label = spec.label!
        argumentsWhenOn = spec.argumentsWhenOn
        argumentsWhenOff = spec.argumentsWhenOff
        super.init(rule: rule, identifier: spec.identifier!)
    }

    public var defaultValue: Bool {
        return false
    }

    public var modelValue: Bool? {
        get {
            return rule.optionValueForKey(identifier)~~~
        }
        set {
            rule.setOptionValue(newValue, forKey: identifier)
        }
    }

    public var effectiveValue: Bool {
        get {
            return modelValue ||| defaultValue
        }
    }

    public override var commandLineArguments: [String] {
        return []
    }

}

