import Foundation
import SwiftyFoundation

public class VersionOption : Option {

    public let label: String = "Version:"

    internal init(rule: Rule) {
        super.init(rule: rule, identifier: "version")
    }

    public var modelValue: LRVersionSpec {
        get {
            return rule.primaryVersionSpec
        }
        set {
            rule.primaryVersionSpec = newValue
        }
    }

    public var effectiveValue: LRVersionSpec {
        get {
            return modelValue
        }
        set {
            modelValue = newValue
        }
    }

}

