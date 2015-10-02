import Foundation

public class CustomArgumentsOption : Option, TextOptionProtocol {

    public let label: String = "Custom arguments:"
    public let placeholder: String? = "--foo --bar=boz"

    internal init(rule: Rule) {
        super.init(rule: rule, identifier: "custom-args")
    }

    public var defaultValue: String {
        get {
            return ""
        }
    }

    public var modelValue: String? {
        get {
            return rule.customArgumentsString
        }
        set {
            rule.customArgumentsString = newValue ?? ""
        }
    }

    public var effectiveValue: String {
        get {
            return modelValue!
        }
        set {
            modelValue = newValue
        }
    }

}
