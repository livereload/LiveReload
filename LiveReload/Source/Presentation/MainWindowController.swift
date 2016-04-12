import Cocoa

public class MainWindowController: NSWindowController {

    private weak var appController: AppController! {
        didSet {
            print("\(self.dynamicType).appController::didSet")
            print("splitViewController = \(splitViewController)")
            print("splitViewController?.splitViewItems[0].viewController = \(splitViewController?.splitViewItems[0].viewController)")
            print("splitViewController?.splitViewItems[1].viewController = \(splitViewController?.splitViewItems[1].viewController)")
        }
    }

    public func setup(appController: AppController) {
        print("\(self.dynamicType).setup")
        self.appController = appController

        let tp = splitViewController!.splitViewItems[0].viewController as! TreePaneViewController
        tp.setup(appController)

        let cp = splitViewController!.splitViewItems[1].viewController as! ContentPaneViewController
        cp.setup(appController)
    }

    private var splitViewController: NSSplitViewController? {
        return contentViewController.map { $0 as! NSSplitViewController }
    }

    public override func windowDidLoad() {
        super.windowDidLoad()

        print("\(self.dynamicType).windowDidLoad")
        print("splitViewController = \(splitViewController)")
    }

}
