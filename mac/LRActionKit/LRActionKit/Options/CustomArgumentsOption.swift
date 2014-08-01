import Foundation
import SwiftyFoundation

public class CustomArgumentsOption : Option {

    let label: String = "Custom arguments:"

    internal init(rule: Rule) {
        super.init(rule: rule, identifier: "custom-args")
    }

    public var modelValue: String {
        get {
            return rule.customArgumentsString
        }
        set {
            rule.customArgumentsString = newValue
        }
    }

    public var effectiveValue: String {
        get {
            return modelValue
        }
    }

}
