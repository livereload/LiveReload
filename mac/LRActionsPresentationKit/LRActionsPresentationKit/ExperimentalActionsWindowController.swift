//
//  ExperimentalActionsWindowController.swift
//  LiveReload UI Experiments
//
//  Created by Andrey Tarantsov on 16.08.2014.
//  Copyright (c) 2014 LiveReload. All rights reserved.
//

import Cocoa
import SwiftyFoundation
import LRCommons

public enum ActionsViewMode: Int {
    case Summary
    case AllOptions
    case AllActions

    var showsAllOptions: Bool {
        return self == .AllOptions
    }

    var showsInactiveActions: Bool {
        return self == .AllActions
    }
}

public class ExperimentalActionsWindowController: NSWindowController, HyperlinkTextFieldDelegate, ActionCellViewDelegate {

    @IBOutlet var tableView: NSTableView!
    @IBOutlet var visibleRulesControl: NSSegmentedControl!

    public var narratives: [String: AnyObject] = [:]

    var items: [Rule] = []
    var visibleItems: [Rule] = []

    var measuringCell: ActionCellView!

    var viewMode = ActionsViewMode.Summary

    public init(windowNibName: String) {
        super.init(window: nil)
        self.setValue(windowNibName, forKey: "windowNibName")
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func narrativeNamed(key: String) -> Narrative {
        return Narrative.parse(narratives[key]! as! [String: AnyObject])
    }

    public override func windowDidLoad() {
        super.windowDidLoad()

        window!.titleVisibility = .Hidden

        var rule = Rule()

        rule = Rule()
        rule.alwaysVisible = true
        rule.checkboxLabel = "Team Sharing"
        rule.introNarrative1 = "Enable to share these build settings with other team members via Gruntfile.js."
        rule.summaryNarrative = "Build settings are synced with Gruntfile.js."
        rule.additionalNarrative = "Enable to share these build settings with other team members via Gruntfile.js."
        rule.docNarratives = []
        items.append(rule)

        rule = Rule()
        rule.enabled = true
        rule.alwaysVisible = true
        rule.analysisNarrative = "You have 4 Less files in src/ subfolder."
        rule.checkboxLabel = "Less"
        rule.introNarrative1 = "Pragmatic stylesheet language with a CSS-like syntax, best known for being used by Bootstrap. [More info]"
        rule.summaryNarrative = "Compile [4 files] from [less/] into [css/]"
        rule.additionalNarrative = "Use the [latest stable] version of LESS (1.4.6)."
        items.append(rule)

        rule = Rule()
        rule.checkboxLabel = "Sass"
        rule.introNarrative1 = narrativeNamed("sass").render().string
        rule.summaryNarrative = "Compile [7 files] from [sass/] into [css/]"
        rule.additionalNarrative = "Using the latest stable version (3.4.0), which [is chosen automatically] based on your code."
        items.append(rule)

        rule = Rule()
        rule.checkboxLabel = "Compass"
        rule.introNarrative1 = "abc"
        rule.summaryNarrative = "Compile 7 files from [sass/] into [css/]."
        rule.additionalNarrative = "Compile [*.sass and *.scss] from [sass/] subfolder into [css/] subfolder.\nYou can start using more libraries and LiveReload will detect them, but you can also [browse the supported libraries] and add them manually."
        items.append(rule)

        rule = Rule()
        rule.checkboxLabel = "CoffeeScript"
        rule.introNarrative1 = "abc"
        rule.summaryNarrative = "Compile 3 files in [scripts/] into [the same folder]."
        rule.additionalNarrative = "Compile [*.sass and *.scss] from [sass/] subfolder into [css/] subfolder.\nYou can start using more libraries and LiveReload will detect them, but you can also [browse the supported libraries] and add them manually."
        items.append(rule)

        rule = Rule()
        rule.checkboxLabel = "es6-transpiler"
        rule.introNarrative1 = "abc"
        rule.summaryNarrative = "Compile 7 files from [sass/] into [css/]."
        rule.additionalNarrative = "Compile [*.sass and *.scss] from [sass/] subfolder into [css/] subfolder.\nYou can start using more libraries and LiveReload will detect them, but you can also [browse the supported libraries] and add them manually."
        items.append(rule)

        rule = Rule()
        rule.checkboxLabel = "TypeScript"
        rule.introNarrative1 = "abc"
        rule.summaryNarrative = "Compile 7 files from [sass/] into [css/]."
        rule.additionalNarrative = "Compile [*.sass and *.scss] from [sass/] subfolder into [css/] subfolder.\nYou can start using more libraries and LiveReload will detect them, but you can also [browse the supported libraries] and add them manually."
        items.append(rule)

        updateVisibleItems(animated: false)
        tableView.reloadData()

        updatedVisibleXControls();
    }

    func configureCellView(cell: ActionCellView, forRow row: Int) {
        let rule = visibleItems[row]
        cell.rule = rule

        cell.checkbox.hidden = rule.checkboxLabel.isEmpty
        cell.checkbox.state = (rule.enabled ? NSOnState : NSOffState)

        configureCellViewCheckboxStyle(cell)
        configureCellViewNarrative(cell)
    }

    func configureCellViewCheckboxStyle(cell: ActionCellView) {
        let rule = cell.rule

        let checkboxColor = (rule.enabled ? NSColor.controlTextColor() : NSColor.secondaryLabelColor())
        cell.checkbox.attributedTitle = NSAttributedString(string: rule.checkboxLabel, attributes: [NSFontAttributeName: NSFont.systemFontOfSize(NSFont.systemFontSizeForControlSize(.RegularControlSize)), NSForegroundColorAttributeName: checkboxColor])
    }

    func configureCellViewNarrative(cell: ActionCellView) {
        let rule = cell.rule

        let paraStyle = NSMutableParagraphStyle()
        paraStyle.paragraphSpacing = 12

        let narrative = (rule.enabled ? (viewMode.showsAllOptions ? rule.detailedNarrative : rule.summaryNarrative) : rule.introNarrative)

        let formattedString = NSMutableAttributedString(string: narrative, attributes: [NSParagraphStyleAttributeName: paraStyle])
        replaceTextWithHyperlinks(formattedString)
        cell.descriptionLabel.attributedStringValue = formattedString
        cell.descriptionLabel.textColor = (rule.enabled ? NSColor.labelColor() : NSColor.secondaryLabelColor())
    }

    func replaceTextWithHyperlinks(ass: NSMutableAttributedString) {
        var scanner = NSScanner(string: ass.string)
        scanner.charactersToBeSkipped = NSCharacterSet()
        let hyperlinkStartCharset = NSCharacterSet(charactersInString: "[")
        let hyperlinkEndCharset = NSCharacterSet(charactersInString: "]")
        while !scanner.atEnd {
            scanner.scanUpToCharactersFromSet(hyperlinkStartCharset, intoString: nil)

            let hyperlinkStart = scanner.scanLocation
            if scanner.scanString("[", intoString: nil) {
                var hyperlinkText: NSString?
                scanner.scanUpToCharactersFromSet(hyperlinkEndCharset, intoString: &hyperlinkText)
                if scanner.scanString("]", intoString: nil) {
                    println("Found hyperlink '\(hyperlinkText)")
                    let hyperlinkEnd = scanner.scanLocation
                    ass.deleteCharactersInRange(NSMakeRange(hyperlinkEnd - 1, 1))
                    ass.deleteCharactersInRange(NSMakeRange(hyperlinkStart, 1))
                    scanner = NSScanner(string: ass.string)
                    scanner.charactersToBeSkipped = NSCharacterSet()
                    scanner.scanLocation = hyperlinkEnd - 2
                    let range = NSMakeRange(hyperlinkStart, hyperlinkEnd - 2 - hyperlinkStart)
                    
                    let url = "http://localhost:5000/\(NSString(string: hyperlinkText!).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)"
                    let s = NSUnderlineStyleSingle | NSUnderlinePatternDot
                    ass.addAttributes([NSLinkAttributeName: NSURL(string: url)!, NSUnderlineStyleAttributeName: (NSUnderlineStyleSingle | NSUnderlinePatternDot), NSUnderlineColorAttributeName: NSColor.secondaryLabelColor()], range: range)
                }
            }
        }
    }

    public func handleURL(url: NSURL, inTextField textField: HyperlinkTextField, withEvent event: NSEvent) {
        println("Got click on \(url)")
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItemWithTitle("Foo", action: nil, keyEquivalent: "")
        menu.addItemWithTitle("Bar", action: nil, keyEquivalent: "")
        menu.addItemWithTitle("Boz", action: nil, keyEquivalent: "")

        let current = menu.itemAtIndex(1)!
        current.state = NSOnState

        let view = event.window!.contentView as! NSView

        menu.popUpMenuPositioningItem(current, atLocation: event.locationInWindow, inView: view)
    }

    func clickedCheckboxInCellView(cell: ActionCellView) {
        cell.rule.enabled = !cell.rule.enabled
        configureCellViewCheckboxStyle(cell)
        configureCellViewNarrative(cell)
        let row = tableView.rowForView(cell)
        if row >= 0 {
            tableView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(index: row))
        }
    }

    func updatedVisibleXControls() {
        visibleRulesControl.selectedSegment = viewMode.rawValue
    }

    @IBAction func toggledVisibleRules(sender: AnyObject) {
        viewMode = ActionsViewMode(rawValue: visibleRulesControl.selectedSegment)!
        updateVisibleItems(animated: true)
    }

    func updateVisibleItems(#animated: Bool) {
        let previousVisibleItems = visibleItems
        if viewMode.showsInactiveActions {
            visibleItems = items
        } else {
            visibleItems = items.filter { $0.enabled || $0.alwaysVisible }
        }

        NSLog("updateVisibleItems, visibleItems = %@, previousVisibleItems = %@", visibleItems, previousVisibleItems)

        if animated {
            tableView.beginUpdates()
            if viewMode.showsInactiveActions {
                let indexSet = NSMutableIndexSet()
                for (index, item) in enumerate(visibleItems) {
                    if find(previousVisibleItems, item) == nil {
                        indexSet.addIndex(index)
                    }
                }
                tableView.insertRowsAtIndexes(indexSet, withAnimation: .EffectFade)
            } else {
                let indexSet = NSMutableIndexSet()
                for (index, item) in enumerate(previousVisibleItems) {
                    if find(visibleItems, item) == nil {
                        indexSet.addIndex(index)
                    }
                }
                tableView.removeRowsAtIndexes(indexSet, withAnimation: .EffectFade)
            }
            tableView.enumerateAvailableRowViewsUsingBlock { (rowView, row) in
                let cell = rowView.viewAtColumn(0) as! ActionCellView
                self.configureCellViewNarrative(cell)
            }
            tableView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(indexesInRange: NSMakeRange(0, tableView.numberOfRows)))
            tableView.endUpdates()
        }
    }

}

extension ExperimentalActionsWindowController : NSTableViewDataSource, NSTableViewDelegate {

    public func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return visibleItems.count
    }

    public func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return visibleItems[row]
    }

    public func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as! ActionCellView
        cell.delegate = self
        cell.descriptionLabel.delegate = self
        configureCellView(cell, forRow: row)
        return cell
    }

    public func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if measuringCell == nil {
            measuringCell = tableView.makeViewWithIdentifier("mainColumn", owner: self) as! ActionCellView
        }
        configureCellView(measuringCell, forRow: row)
        return measuringCell.fittingSize.height
    }

}


private func joinStr(delimiter: String, a: String, b: String) -> String {
    if a.isEmpty {
        return b
    } else if b.isEmpty {
        return a
    } else {
        return a + delimiter + b
    }
}

private func joinStr(delimiter: String, a: String, b: String, c: String, more: String...) -> String {
    var result = joinStr(delimiter, a, b)
    result = joinStr(delimiter, result, c)
    for d in more {
        result = joinStr(delimiter, result, d)
    }
    return result
}


class Rule : NSObject {

    var enabled = false
    var alwaysVisible = false
    var checkboxLabel: String = ""
    var introNarrative1: String = ""
    var analysisNarrative: String = ""
    var docNarratives: [String] = ["[Docs]", "[Version History]", "[Examples]", "[Issues]"]
    var summaryNarrative: String = ""
    var additionalNarrative: String = ""
    var narrative: Narrative = Narrative(paragraphs: [])

    var introNarrative: String {
        return introNarrative1
    }

    var expandedIntroNarrative: String {
        return joinStr("\n", introNarrative1, analysisNarrative, join("   ", docNarratives))
    }

    var detailedNarrative: String {
        return joinStr("\n", summaryNarrative, additionalNarrative)
    }

}


public class NarrativeElement {

    func render(intoAttributedString attributedString: NSMutableAttributedString) {
    }

}

public class Narrative : NarrativeElement {

    public let paragraphs: [ParagraphNarrativeElement]

    public init(paragraphs: [ParagraphNarrativeElement]) {
        self.paragraphs = paragraphs
    }

    public class func parse(data: [String: AnyObject]) -> Narrative {
        var paragraphs: [ParagraphNarrativeElement] = []
        let paragraphsData = data["paragraphs"]! as! [AnyObject]
        for paragraphData in paragraphsData {
            paragraphs <<< ParagraphNarrativeElement.parse(paragraphData as! [String: AnyObject])
        }

        return Narrative(paragraphs: paragraphs)
    }

    public func render() -> NSAttributedString {
        let s = NSMutableAttributedString()
        render(intoAttributedString: s)
        replaceTextWithHyperlinks(s)
        return s
    }

    override func render(intoAttributedString attributedString: NSMutableAttributedString) {
        for (index, paragraph) in enumerate(paragraphs) {
            if index > 0 {
                attributedString.appendAttributedString(NSAttributedString(string: "\n"))
            }
            paragraph.render(intoAttributedString: attributedString)
        }
    }

    private func replaceTextWithHyperlinks(ass: NSMutableAttributedString) {
        var scanner = NSScanner(string: ass.string)
        scanner.charactersToBeSkipped = NSCharacterSet()
        let hyperlinkStartCharset = NSCharacterSet(charactersInString: "[")
        let hyperlinkEndCharset = NSCharacterSet(charactersInString: "]")
        while !scanner.atEnd {
            scanner.scanUpToCharactersFromSet(hyperlinkStartCharset, intoString: nil)

            let hyperlinkStart = scanner.scanLocation
            if scanner.scanString("[", intoString: nil) {
                var hyperlinkText: NSString?
                scanner.scanUpToCharactersFromSet(hyperlinkEndCharset, intoString: &hyperlinkText)
                if scanner.scanString("]", intoString: nil) {
                    println("Found hyperlink '\(hyperlinkText)")
                    let hyperlinkEnd = scanner.scanLocation
                    ass.deleteCharactersInRange(NSMakeRange(hyperlinkEnd - 1, 1))
                    ass.deleteCharactersInRange(NSMakeRange(hyperlinkStart, 1))
                    scanner = NSScanner(string: ass.string)
                    scanner.charactersToBeSkipped = NSCharacterSet()
                    scanner.scanLocation = hyperlinkEnd - 2
                    let range = NSMakeRange(hyperlinkStart, hyperlinkEnd - 2 - hyperlinkStart)
                    let url = "http://localhost:5000/\(NSString(string: hyperlinkText!).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding))"
                    ass.addAttributes([NSLinkAttributeName: NSURL(string: url)!, NSUnderlineStyleAttributeName: (NSUnderlineStyleSingle | NSUnderlinePatternDot), NSUnderlineColorAttributeName: NSColor.secondaryLabelColor()], range: range)
                }
            }
        }
    }

}

public class ParagraphNarrativeElement : NarrativeElement {

    public let children: [NarrativeElement]

    public init(children: [NarrativeElement]) {
        self.children = children
    }

    public class func parse(data: [String: AnyObject]) -> ParagraphNarrativeElement {
        var children: [NarrativeElement] = []
        if let childrenData: AnyObject = data["children"] {
            for childData in childrenData as! [AnyObject] {
                children <<< ItemNarrativeElement.parse(childData as! [String: AnyObject])
            }
        } else {
            children <<< ItemNarrativeElement.parse(data)
        }

        return ParagraphNarrativeElement(children: children)
    }

    override func render(intoAttributedString attributedString: NSMutableAttributedString) {
        for (index, child) in enumerate(children) {
            if index > 0 {
                attributedString.appendAttributedString(NSAttributedString(string: " "))
            }
            child.render(intoAttributedString: attributedString)
        }
    }

}

public class ItemNarrativeElement : NarrativeElement {

    public let states: [ItemStateNarrativeElement]

    public init(states: [ItemStateNarrativeElement]) {
        self.states = states
    }

    public class func parse(data: [String: AnyObject]) -> ItemNarrativeElement {
        var states: [ItemStateNarrativeElement] = []
        if let statesData: AnyObject = data["states"] {
            for stateData in statesData as! [AnyObject] {
                states <<< ItemStateNarrativeElement.parse(stateData as! [String: AnyObject])
            }
        } else {
            states <<< ItemStateNarrativeElement.parse(data)
        }

        return ItemNarrativeElement(states: states)
    }

    override func render(intoAttributedString attributedString: NSMutableAttributedString) {
        states[0].render(intoAttributedString: attributedString)
    }

}

public class ItemStateNarrativeElement : NarrativeElement {

    public let stateName: String
    public let markdown: String

    public init(stateName: String, markdown: String) {
        self.stateName = stateName
        self.markdown = markdown
    }

    public class func parse(data: [String: AnyObject]) -> ItemStateNarrativeElement {
        let stateName: String = data["state"] ~|||~ ""
        let markdown: String = data["markdown"] ~|||~ ""
        return ItemStateNarrativeElement(stateName: stateName, markdown: markdown)
    }

    override func render(intoAttributedString attributedString: NSMutableAttributedString) {
        attributedString.appendAttributedString(NSAttributedString(string: markdown))
    }

}


protocol ActionCellViewDelegate : class {

    func clickedCheckboxInCellView(sender: ActionCellView)

}

class ActionCellView : NSTableCellView {

    var rule: Rule!
    var delegate: ActionCellViewDelegate!

    @IBOutlet var contentView: NSView!
    @IBOutlet var checkbox: NSButton!
    @IBOutlet var descriptionLabel: NSTextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        checkbox.target = self
        checkbox.action = "clicked:"
    }

    @IBAction func clicked(sender: AnyObject) {
        delegate.clickedCheckboxInCellView(self)
    }

}
