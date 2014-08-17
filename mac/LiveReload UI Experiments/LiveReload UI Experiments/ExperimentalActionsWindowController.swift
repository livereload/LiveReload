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

    override func windowDidLoad() {
        super.windowDidLoad()

        window.titleVisibility = .Hidden

        var rule = Rule()

        rule = Rule()
        rule.checkboxLabel = "Sharing"
        rule.introNarrative = "Enable to share these build settings with other team members via Gruntfile.js."
        rule.detailedNarrative = "Enable to share these build settings with other team members via Gruntfile.js."
        items.append(rule)

        rule = Rule()
        rule.enabled = true
        rule.checkboxLabel = "Less"
        rule.introNarrative = "A CSS pre-processor with a CSS-like syntax. It adds variables, mixins, functions and other techniques to make stylesheets more maintainable, themable and extendable."
        rule.detailedNarrative = "Compile [*.less] from [less/] subfolder into [css/] subfolder.\nUse the [latest stable] version of LESS (1.4.6)"
        items.append(rule)

        rule = Rule()
        rule.checkboxLabel = "Sass"
        rule.introNarrative = "“the most mature, stable, and powerful professional grade CSS extension language in the world”"
        rule.detailedNarrative = "Compile [*.sass and *.scss] from [sass/] subfolder into [css/] subfolder.\nYou can start using more libraries and LiveReload will detect them, but you can also [browse the supported libraries] and add them manually."
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

        if rule.checkboxLabel.isEmpty {
            cell.checkbox.hidden = true
            cell.checkbox.title = ""
        } else {
            cell.checkbox.hidden = false
            cell.checkbox.title = rule.checkboxLabel
        }
        cell.checkbox.state = (rule.enabled ? NSOnState : NSOffState)

        configureCellViewNarrative(cell)
    }

    func configureCellViewNarrative(cell: ActionCellView) {
        let rule = cell.rule

        let paraStyle = NSMutableParagraphStyle()
        paraStyle.paragraphSpacing = 12

        let narrative = (rule.enabled ? rule.detailedNarrative : rule.introNarrative)

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
        let hyperlinkStartCharset = NSCharacterSet(charactersInString: "[")
        let hyperlinkEndCharset = NSCharacterSet(charactersInString: "]")
        while !scanner.atEnd {
            scanner.scanUpToCharactersFromSet(hyperlinkStartCharset, intoString: nil)

            let hyperlinkStart = scanner.scanLocation
            if scanner.scanString("[", intoString: nil) {
                var hyperlinkText: NSString?
                scanner.scanUpToCharactersFromSet(hyperlinkEndCharset, intoString: &hyperlinkText)
                if scanner.scanString("]", intoString: nil) {
                    let hyperlinkEnd = scanner.scanLocation
                    ass.deleteCharactersInRange(NSMakeRange(hyperlinkEnd - 1, 1))
                    ass.deleteCharactersInRange(NSMakeRange(hyperlinkStart, 1))
                    scanner = NSScanner(string: ass.string)
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

    func clickedCheckboxInCellView(sender: ActionCellView) {
        sender.rule.enabled = !sender.rule.enabled
        configureCellViewNarrative(sender)
        let row = tableView.rowForView(sender)
        if row >= 0 {
            tableView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(index: row))
        }
    }

}

class Rule : NSObject {

    var enabled = false
    var checkboxLabel: String = ""
    var introNarrative: String = ""
    var detailedNarrative: String = ""

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
