import Cocoa
import LRProjectKit

public class TreePaneViewController: NSViewController {

    private var workspace: Workspace!

    private let rootItem = RootTreeItem()

    @IBOutlet var outlineView: NSOutlineView!

    public func setup(appController: AppController) {
        print("\(self.dynamicType).setup")
        workspace = appController.app.workspace
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

    public func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        let item = mapItem(item)
        return item.isExpandable
    }

    public func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        let item = mapItem(item)
        return item.isSelectable
    }

    public func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        let item = mapItem(item)
        switch item {
        case _ as ProjectsHeaderTreeItem:
            let view = outlineView.makeViewWithIdentifier("HeaderCell", owner: self)! as! NSTableCellView
            view.textField!.stringValue = "Projects"
            return view
        case let projectItem as ProjectTreeItem:
            let view = outlineView.makeViewWithIdentifier("DataCell", owner: self)! as! NSTableCellView
            view.textField!.stringValue = projectItem.project.displayName
            return view
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
