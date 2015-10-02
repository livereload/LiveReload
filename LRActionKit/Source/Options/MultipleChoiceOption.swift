import Foundation
import ExpressiveCasting
import ExpressiveCocoa

public class MultipleChoiceOptionType : OptionType {
    public override var name: String {
        return "popup"
    }

    public override func parse(manifest: [String: AnyObject], _ errorSink: LRManifestErrorSink) -> OptionSpec? {
        let spec = MultipleChoiceOptionSpec()
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
        let items: [MultipleChoiceOptionItem]? = ArrayValue(manifest["items"]) { MultipleChoiceOptionType.parseItem($0 as! [String: AnyObject], index: index++) }
        if let items = items {
            spec.items = items
        } else {
            errorSink.addErrorMessage("Invalid items format, must be an array of dictionaries with 3 keys: 'id', 'label', 'args'")
            return false;
        }

        return true
    }

    private class func parseItem(manifest: [String: AnyObject], index: Int) -> MultipleChoiceOptionItem? {
        let identifier: String? = manifest["id"]~~~
        let label: String? = manifest["label"]~~~
        let arguments: [String] = P2ParseCommandLineSpec(manifest["args"]) 
        if identifier != nil && label != nil && !identifier!.isEmpty && !label!.isEmpty {
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

    internal override func newOption(rule rule: Rule) -> Option {
        return MultipleChoiceOption(rule: rule, spec: self)
    }
}

public class MultipleChoiceOption : Option, MultipleChoiceOptionProtocol {

    public let label: String
    public let items: [MultipleChoiceOptionItem]

    public private(set) var unknownItem: MultipleChoiceOptionItem? = nil {
        didSet {
            // TODO: when we implement syncing of settings, notify the UI that the list of items has changed
        }
    }

    private init(rule: Rule, spec: MultipleChoiceOptionSpec) {
        label = spec.label!
        items = spec.items
        super.init(rule: rule, identifier: spec.identifier!)

        modelValueDidChange()
        // right now the only case when an unknown item may be encountered is on initial config loading.
        // TODO: when we implement syncing of settings, listen to model value changes and call modelValueDidChange
    }

    private func findItem(identifier identifier: String, createIfMissing: Bool = true) -> MultipleChoiceOptionItem? {
        for item in items {
            if item.identifier == identifier {
                return item
            }
        }
        if let unknownItem = unknownItem {
            if unknownItem.identifier == identifier {
                return unknownItem
            }
        }
        return nil
    }

    private func lookupItem(identifier identifier: String) -> MultipleChoiceOptionItem {
        if let item = findItem(identifier: identifier) {
            return item
        } else {
            let item = MultipleChoiceOptionItem(identifier: identifier, label: "\(identifier) (unsupported)", index: items.count, arguments: [])
            unknownItem = item
            return item
        }
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

    public var effectiveItem: MultipleChoiceOptionItem {
        get {
            if let item = findItem(identifier: effectiveValue) {
                return item
            } else {
                fatalError("modelValueDidChange hasn't been called after modelValue has changed to an unknown item")
            }
        }
        set {
            effectiveValue = newValue.identifier
        }
    }

    public override var commandLineArguments: [String] {
        return effectiveItem.arguments
    }

    private func modelValueDidChange() {
        if let identifier = modelValue {
            lookupItem(identifier: identifier)
        } else {
            if unknownItem != nil {
                unknownItem = nil
            }
        }
    }

}

