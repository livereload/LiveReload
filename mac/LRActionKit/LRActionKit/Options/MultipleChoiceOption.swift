import Foundation
import SwiftyFoundation
import LRCommons

public class MultipleChoiceOptionType : OptionType {
    public override var name: String {
        return "popup"
    }

    public override func parse(manifest: [String: AnyObject], _ errorSink: LRManifestErrorSink) -> OptionSpec? {
        var spec = MultipleChoiceOptionSpec()
        if !parse(into: spec, manifest, errorSink) {
            return nil
        }
        if !spec.validate(errorSink) {
            return nil
        }
        return spec
    }

    internal func parse(into spec: MultipleChoiceOptionSpec, _ manifest: [String: AnyObject], _ errorSink: LRManifestErrorSink) -> Bool {
        if !parseCommon(into: spec, manifest, errorSink) {
            return false
        }

        var index = 0
        let items: [MultipleChoiceOptionItem]? = ArrayValue(manifest["items"]) { MultipleChoiceOptionItem.parse($0 as [String: AnyObject], index: index++) }
        if let items = items {
            spec.items = items
        } else {
            errorSink.addErrorMessage("Invalid items format, must be an array of dictionaries with 3 keys: 'id', 'label', 'args'")
            return false;
        }

        return true
    }
}

public class MultipleChoiceOptionItem : NSObject {

    public let identifier: String
    public let label: String
    public let index: Int
    public let arguments: [String]

    public init(identifier: String, label: String, index: Int, arguments: [String]) {
        self.identifier = identifier
        self.label = label
        self.index = index
        self.arguments = arguments
    }

    private class func parse(manifest: [String: AnyObject], index: Int) -> MultipleChoiceOptionItem? {
        let identifier: String? = manifest["id"]~~~
        let label: String? = manifest["label"]~~~
        let arguments: [String] = P2ParseCommandLineSpec(manifest["args"]) as [String]
        if identifier && label && !identifier!.isEmpty && !label!.isEmpty {
            return MultipleChoiceOptionItem(identifier: identifier!, label: label!, index: index, arguments: arguments)
        } else {
            return nil
        }
    }

}

internal class MultipleChoiceOptionSpec : OptionSpec {
    var items: [MultipleChoiceOptionItem] = []

    override func validate(errorSink: LRManifestErrorSink) -> Bool {
        if !super.validate(errorSink) {
            return false
        }
        if items.isEmpty {
            errorSink.addErrorMessage("Missing items")
            return false
        }
        return true
    }

    public override func newOption(#rule: Rule) -> Option {
        return MultipleChoiceOption(rule: rule, spec: self)
    }
}

public class MultipleChoiceOption : Option {

    public let label: String
    public let items: [MultipleChoiceOptionItem]

    private init(rule: Rule, spec: MultipleChoiceOptionSpec) {
        label = spec.label!
        items = spec.items
        super.init(rule: rule, identifier: spec.identifier!)
    }

    public func findItem(#identifier: String) -> MultipleChoiceOptionItem? {
        for item in items {
            if item.identifier == identifier {
                return item
            }
        }
        return nil
    }

    public var defaultValue: String {
        return items[0].identifier
    }

    // note: this CAN be set to a value that's not in self.items
    // (e.g. if a newer version of LiveReload has more items defined)
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
            return modelValue ||| defaultValue
        }
    }

    public var effectiveItem: MultipleChoiceOptionItem? {
        get {
            return findItem(identifier: effectiveValue)
        }
    }

    public override var commandLineArguments: [String] {
        if let item = effectiveItem {
            return item.arguments
        } else {
            return []
        }
    }

}

