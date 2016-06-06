import Cocoa
import LRProjectKit

public class TreePaneViewController: NSViewController {

    private var workspace: Workspace!

    private let rootItem = RootTreeItem()

    private let scrollView = NSScrollView()
    private let outlineView = NSOutlineView()
    private let column = NSTableColumn(identifier: "name")

    public func setup(appController: AppController) {
        print("\(self.dynamicType).setup")
        workspace = appController.app.workspace
    }

    public override func loadView() {
        view = scrollView
        scrollView.documentView = outlineView

        outlineView.setDataSource(self)
        outlineView.setDelegate(self)
        outlineView.rowSizeStyle = .Small
        outlineView.headerView = nil
        outlineView.selectionHighlightStyle = .SourceList

        column.title = "Name"
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        outlineView.reloadData()
        outlineView.expandItem(rootItem.projectsHeader, expandChildren: true)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        print("\(self.dynamicType).viewDidLoad")
    }

}

extension TreePaneViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {

    public func outlineViewSelectionDidChange(notification: NSNotification) {
    }

    public func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        let item = mapItem(item)
        return item.children.count
    }

    public func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        let item = mapItem(item)
        return item.children[index]
    }

    public func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        return mapItem(item).isGroupItem
    }

    public func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        return mapItem(item).isExpandable
    }

    public func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        return mapItem(item).isSelectable
    }

    public func outlineView(outlineView: NSOutlineView, shouldShowOutlineCellForItem item: AnyObject) -> Bool {
        return false
    }

    public func outlineView(outlineView: NSOutlineView, shouldCollapseItem item: AnyObject) -> Bool {
        return false
    }

    public func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        let item = mapItem(item)
        switch item {
        case _ as ProjectsHeaderTreeItem:
            let label = NSTextField()
            label.bordered = false
            label.drawsBackground = false
            label.textColor = NSColor.headerColor()
            label.font = NSFont.boldSystemFontOfSize(NSFont.smallSystemFontSize())

//            let imageView = NSImageView()
//            imageView

            let cell = NSTableCellView()
            cell.textField = label
            cell.addSubview(label)

            label.stringValue = "Projects"

            return cell

        case let projectItem as ProjectTreeItem:
            let label = NSTextField()
            label.bordered = false
            label.drawsBackground = false
            label.textColor = NSColor.controlTextColor()
            label.font = NSFont.systemFontOfSize(NSFont.systemFontSize())
//            let imageView = NSImageView()
//            imageView.im

            let cell = NSTableCellView()
            cell.textField = label
            cell.addSubview(label)

            label.stringValue = projectItem.project.displayName

            return cell

        default:
            return nil
        }
    }

    private func mapItem(item: AnyObject?) -> TreeItem {
        if let item = item {
            return item as! TreeItem
        } else {
            return rootItem
        }
    }

}
