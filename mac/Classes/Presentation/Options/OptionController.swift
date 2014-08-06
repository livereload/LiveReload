import Foundation
import SwiftyFoundation
import LRCommons.ATMacViewCreation
import LRActionKit

public class OptionController: NSObject {

    internal override init() {

    }

    public func loadModelValues() {

    }

    public func saveModelValues() {

    }

    internal func presentedValueDidChange() {
        saveModelValues()
    }

    public func renderInOptionsView(optionsView: LROptionsView) {
        fatalError("Must override")
    }

    @objc
    public class func controllerForOption(option: Option) -> OptionController? {
        switch option {
        case let o as CheckboxOption:
            return CheckboxOptionController(option: o)
        case let o as MultipleChoiceOption:
            return PopupOptionController(option: o)
        case let o as TextOption:
            return TextOptionController(option: o)
        default:
            return nil
        }
    }

}


public class CheckboxOptionController : OptionController {

    private let option: CheckboxOption
    private var view: NSButton!

    public init(option: CheckboxOption) {
        self.option = option
        super.init()
    }

    public override func renderInOptionsView(optionsView: LROptionsView) {
        view = NSButton(title: option.label, type:.SwitchButton, bezelStyle:.RoundRectBezelStyle).withTarget(self, action: "checkboxClicked:")
        optionsView.addOptionView(view, withLabel:"", flags:.LabelAlignmentBaseline)
        loadModelValues()
    }

    public override func loadModelValues() {
        view.state = option.effectiveValue ? NSOnState : NSOffState
    }

    public override func saveModelValues() {
        option.effectiveValue = (view.state == NSOnState)
    }

    public func checkboxClicked(sender: NSButton) {
        presentedValueDidChange()
    }

}


public class PopupOptionController : OptionController {

    private let option: MultipleChoiceOption
    private var view: NSPopUpButton!

    public init(option: MultipleChoiceOption) {
        self.option = option
        super.init()
    }

    public override func renderInOptionsView(optionsView: LROptionsView) {
        view = NSPopUpButton.popUpButton().withTarget(self, action: "popUpSelectionDidChange:")
        view.addItemsWithTitles(option.items.map { $0.label })
        optionsView.addOptionView(view, withLabel:option.label, flags:.LabelAlignmentBaseline)
        loadModelValues()
    }

    public override func loadModelValues() {
        if let item = option.effectiveItem {
            view.selectItemAtIndex(item.index)
        }
    }

    public override func saveModelValues() {
        let index = view.indexOfSelectedItem
        if index < 0 {
            option.modelValue = nil
        } else {
            option.effectiveValue = option.items[index].identifier
        }
    }

    public func popUpSelectionDidChange(sender: NSPopUpButton) {
        presentedValueDidChange()
    }

}


public class TextOptionController : OptionController, NSTextFieldDelegate {

    private let option: TextOption
    private var view: NSTextField!

    public init(option: TextOption) {
        self.option = option
        super.init()
    }

    public override func renderInOptionsView(optionsView: LROptionsView) {
        view = NSTextField.editableField()
        if let placeholder: String = option.placeholder {
            (view.cell() as NSTextFieldCell).placeholderString = placeholder
        }
        view.delegate = self
        optionsView.addOptionView(view, withLabel:option.label, flags:.LabelAlignmentBaseline)
        loadModelValues()
    }

    public override func loadModelValues() {
        view.stringValue = option.effectiveValue
    }

    public override func saveModelValues() {
        option.effectiveValue = view.stringValue
    }

    public override func controlTextDidChange(notification: NSNotification) {
        presentedValueDidChange()
    }

}
