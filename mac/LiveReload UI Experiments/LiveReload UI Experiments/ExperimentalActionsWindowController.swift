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

class ExperimentalActionsWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate, HyperlinkTextFieldDelegate, ActionCellViewDelegate {

    @IBOutlet var tableView: NSTableView!

    var items: [Rule] = []

    var measuringCell: ActionCellView!

    var additionalMode = false
    var expandedMode = false

    override func windowDidLoad() {
        super.windowDidLoad()

        window.titleVisibility = .Hidden

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
        rule.introNarrative1 = "A CSS pre-processor with a CSS-like syntax. It adds variables, mixins, functions and other techniques to make stylesheets more maintainable, themable and extendable."
        rule.summaryNarrative = "Compile 4 files from [less/] into [css/]"
        rule.additionalNarrative = "Using the [latest stable] version of LESS (1.4.6)"
        items.append(rule)

        rule = Rule()
        rule.alwaysVisible = false
        rule.checkboxLabel = "Sass"
        rule.introNarrative1 = "“the most mature, stable, and powerful professional grade CSS extension language in the world”"
        rule.summaryNarrative = "Compile 7 files from [sass/] into [css/]."
        rule.additionalNarrative = "Compile [*.sass and *.scss] from [sass/] subfolder into [css/] subfolder.\nYou can start using more libraries and LiveReload will detect them, but you can also [browse the supported libraries] and add them manually."
        items.append(rule)

        tableView.reloadData()
    }

    func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
        return items.count
    }

    func tableView(tableView: NSTableView!, objectValueForTableColumn tableColumn: NSTableColumn!, row: Int) -> AnyObject! {
        return items[row]
    }

    func tableView(tableView: NSTableView!, viewForTableColumn tableColumn: NSTableColumn!, row: Int) -> NSView! {
        let cell = tableView.makeViewWithIdentifier(tableColumn.identifier, owner: self) as ActionCellView
        cell.delegate = self
        cell.descriptionLabel.delegate = self
        configureCellView(cell, forRow: row)
        return cell
    }

    func configureCellView(cell: ActionCellView, forRow row: Int) {
        let rule = items[row]
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

        let narrative = (rule.enabled ? (expandedMode ? rule.detailedNarrative : rule.summaryNarrative) : (additionalMode || expandedMode ? rule.expandedIntroNarrative : rule.introNarrative))

        let formattedString = NSMutableAttributedString(string: narrative, attributes: [NSParagraphStyleAttributeName: paraStyle])
        replaceTextWithHyperlinks(formattedString)
        cell.descriptionLabel.attributedStringValue = formattedString
        cell.descriptionLabel.textColor = (rule.enabled ? NSColor.labelColor() : NSColor.secondaryLabelColor())
    }

    func tableView(tableView: NSTableView!, heightOfRow row: Int) -> CGFloat {
        if measuringCell == nil {
            measuringCell = tableView.makeViewWithIdentifier("mainColumn", owner: self) as ActionCellView
        }
        configureCellView(measuringCell, forRow: row)
        return measuringCell.fittingSize.height
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
                    ass.addAttributes([NSLinkAttributeName: NSURL(string: "http://localhost:5000/\(NSString(string: hyperlinkText!).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding))"), NSUnderlineStyleAttributeName: NSUnderlineStyleSingle | NSUnderlinePatternDot, NSUnderlineColorAttributeName: NSColor.secondaryLabelColor()], range: range)
                }
            }
        }
    }

    func handleURL(url: NSURL!, inTextField textField: HyperlinkTextField!) {
        println("Got click on \(url)")
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

    @IBAction func toggleAdditionMode(sender: AnyObject) {
        additionalMode = !additionalMode
        tableView.reloadData()
    }

    @IBAction func toggleExpandedMode(sender: AnyObject) {
        expandedMode = !expandedMode
        tableView.enumerateAvailableRowViewsUsingBlock { (rowView, row) in
            let cell = rowView.viewAtColumn(0) as ActionCellView
            self.configureCellViewNarrative(cell)
        }
        tableView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(indexesInRange: NSMakeRange(0, tableView.numberOfRows)))
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
