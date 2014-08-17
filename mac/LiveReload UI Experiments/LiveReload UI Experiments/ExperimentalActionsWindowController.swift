//
//  ExperimentalActionsWindowController.swift
//  LiveReload UI Experiments
//
//  Created by Andrey Tarantsov on 16.08.2014.
//  Copyright (c) 2014 LiveReload. All rights reserved.
//

import Cocoa

class ExperimentalActionsWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate, HyperlinkTextFieldDelegate {

    @IBOutlet var tableView: NSTableView!

    var items: [Rule] = []

    var measuringCell: ActionCellView!

    override func windowDidLoad() {
        super.windowDidLoad()

        var rule = Rule()

        rule = Rule()
        rule.checkboxLabel = ""
        rule.description = "This project settings are stored locally and won't be shared with other team members."
        items.append(rule)

        rule = Rule()
        rule.checkboxLabel = "LESS"
        rule.description = "Compile *.less from less/ subfolder into css/ subfolder.\nUse the latest stable version of LESS (1.4.6)"
        items.append(rule)

        rule = Rule()
        rule.checkboxLabel = "Sass"
        rule.description = "Compile *.sass and *.scss from sass/ subfolder into css/ subfolder.\nYou can start using more libraries and LiveReload will detect them, but you can also browse the supported libraries and add them manually."
        items.append(rule)

        tableView.reloadData()
    }

    func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
        return items.count
    }

    func tableView(tableView: NSTableView!, viewForTableColumn tableColumn: NSTableColumn!, row: Int) -> NSView! {
        let cell = tableView.makeViewWithIdentifier(tableColumn.identifier, owner: self) as ActionCellView
        configureCellView(cell, forRow: row)
        return cell
    }

    func configureCellView(cell: ActionCellView, forRow row: Int) {
        cell.descriptionLabel.delegate = self
        
        let rule = items[row]

        if rule.checkboxLabel.isEmpty {
            cell.checkbox.hidden = true
            cell.checkbox.title = ""
        } else {
            cell.checkbox.hidden = false
            cell.checkbox.title = rule.checkboxLabel
        }

        let paraStyle = NSMutableParagraphStyle()
        paraStyle.paragraphSpacing = 12

        let formattedString = NSMutableAttributedString(string: rule.description, attributes: [NSParagraphStyleAttributeName: paraStyle])
        replaceTextWithHyperlink(formattedString, text: "stored locally")
        replaceTextWithHyperlink(formattedString, text: "*.less")
        replaceTextWithHyperlink(formattedString, text: "*.sass and *.scss")
        replaceTextWithHyperlink(formattedString, text: "less/ subfolder")
        replaceTextWithHyperlink(formattedString, text: "css/ subfolder")
        replaceTextWithHyperlink(formattedString, text: "sass/ subfolder")
        replaceTextWithHyperlink(formattedString, text: "latest stable version")
        cell.descriptionLabel.attributedStringValue = formattedString
    }

    func tableView(tableView: NSTableView!, heightOfRow row: Int) -> CGFloat {
        if measuringCell == nil {
            measuringCell = tableView.makeViewWithIdentifier("mainColumn", owner: self) as ActionCellView
        }
        configureCellView(measuringCell, forRow: row)
        return measuringCell.fittingSize.height
    }

    func replaceTextWithHyperlink(ass: NSMutableAttributedString, text: String) {
        let range = (ass.string as NSString).rangeOfString(text)
        if range.location != NSNotFound {
            ass.addAttributes([NSLinkAttributeName: NSURL(string: "http://localhost:5000/"), NSUnderlineStyleAttributeName: NSUnderlineStyleSingle | NSUnderlinePatternDot, NSUnderlineColorAttributeName: NSColor.secondaryLabelColor()], range: range)
        }
    }

    func handleURL(url: NSURL!, inTextField textField: HyperlinkTextField!) {
        println("Got click on \(url)")
    }

}

class Rule {

    var checkboxLabel: String = ""
    var description: String = ""

}

class ActionCellView : NSTableCellView {

    @IBOutlet var contentView: NSView!
    @IBOutlet var checkbox: NSButton!
    @IBOutlet var descriptionLabel: NSTextField!

}
