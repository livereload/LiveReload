import Foundation
import SwiftyFoundation
import LRCommons
import LRActionKit


public class VersionOptionView : NSView {

    public var popUpView: NSPopUpButton!
    public var labelView: NSTextField!

    public init() {
        super.init(frame: CGRectZero)
        initialize()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    private func initialize() {
        popUpView = NSPopUpButton.at_popUpButton()
        labelView = NSTextField.staticLabelWithString("")
        addSubview(popUpView)
        addSubview(labelView)

        let views = ["popUpView": popUpView, "labelView": labelView]
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[popUpView]-[labelView]|", options:.AlignAllBaseline, metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[popUpView]|", options:nil, metrics: nil, views: views))
    }

}


public class VersionOptionController : OptionController {

    private var o = Observation()

    private let option: VersionOption
    private var specs: [LRVersionSpec] = []
    private var view: VersionOptionView!

    public init(option: VersionOption) {
        self.option = option
        super.init()
        o.on(LRContextAction.didChangeVersionsNotification, self, VersionOptionController.updateVersionSpecs)
        o.on(LRRuleEffectiveVersionDidChangeNotification, self, VersionOptionController.updateEffectiveVersion)
    }

    public override func renderInOptionsView(optionsView: LROptionsView) {
        view = VersionOptionView()
        view.popUpView.withTarget(self, action: "popUpSelectionDidChange:")
        view.translatesAutoresizingMaskIntoConstraints = false

        updateVersionSpecs()
        updateEffectiveVersion()

        optionsView.addOptionView(view, withLabel:option.label, alignedToView:view.popUpView, flags:.LabelAlignmentBaseline)
        loadModelValues()
    }

    public override func loadModelValues() {
        if let index = find(specs, option.effectiveValue) {
            view.popUpView.selectItemWithTag(1 + index)
        } else {
            // TODO: clear selection?
        }
    }

    public override func saveModelValues() {
        if let menuItem = view.popUpView.selectedItem {
            let spec = menuItem.representedObject as! LRVersionSpec
            option.effectiveValue = spec
        }
    }

    public func popUpSelectionDidChange(sender: NSPopUpButton) {
        presentedValueDidChange()
    }

    private func updateVersionSpecs() {
        specs = option.rule.contextAction.versionSpecs

        var groups: [LRVersionSpecType: [NSMenuItem]] = [:]
        groups[.StableAny]   = []
        groups[.StableMajor] = []
        groups[.MajorMinor]  = []
        groups[.Specific]    = []
        groups[.Unknown]     = []

        for (index, spec) in enumerate(specs) {
            let item = NSMenuItem(title: spec.title, action: nil, keyEquivalent: "")
            item.representedObject = spec
            item.tag = 1 + index

            groups[spec.type]!.append(item)
        }

        var groupsInOrder: [[NSMenuItem]] = []
        groupsInOrder <<< groups[.StableAny]!
        groupsInOrder <<< groups[.StableMajor]!
        groupsInOrder <<< groups[.MajorMinor]!
        groupsInOrder <<< groups[.Specific]!
        groupsInOrder <<< groups[.Unknown]!

        let items = flattenWithSeparator(groupsInOrder, separator: { NSMenuItem.separatorItem() })

        view.popUpView.removeAllItems()
        for item in items {
            view.popUpView.menu!.addItem(item)
        }

        loadModelValues()
    }

    private func updateEffectiveVersion() {
        let ver = option.rule.effectiveVersion?.primaryVersion.description ?? "none"
        view.labelView.stringValue = "(in use: \(ver))"
    }

}
