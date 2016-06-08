import Cocoa
import LRProjectKit

public class TreePaneViewController: NSViewController {

    public weak var delegate: TreePaneViewControllerDelegate?

    private var selectedItem: TreeItem? = nil

    public var selectedProject: Project? {
        if let selectedItem = selectedItem as? ProjectTreeItem {
            return selectedItem.project
        } else {
            return nil
        }
    }

    private let workspace: Workspace

    private let rootItem = RootTreeItem()

    private let scrollView = NSScrollView()
    private let outlineView = NSOutlineView()
    private let column = NSTableColumn(identifier: "name")

    public init(workspace: Workspace) {
        self.workspace = workspace
        super.init(nibName: nil, bundle: nil)!
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        let idx = outlineView.selectedRow
        if idx == -1 {
            selectionDidChange(nil)
        } else {
            let obj = outlineView.itemAtRow(idx)
            let item = mapItem(obj)
            selectionDidChange(item)
        }
    }

    private func selectionDidChange(item: TreeItem?) {
        guard selectedItem !== item else {
            return
        }
        selectedItem = item
        delegate?.selectedItemDidChange(inTreePaneViewController: self)
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


// MARK: - Delegate

public protocol TreePaneViewControllerDelegate: class {

    func selectedItemDidChange(inTreePaneViewController viewController: TreePaneViewController)
    
}
