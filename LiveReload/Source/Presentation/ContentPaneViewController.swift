import Cocoa

public class ContentPaneViewController: NSViewController {

    private var contentViewController: NSViewController?

    public override func loadView() {
        view = NSView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        print("\(self.dynamicType).viewDidLoad")
    }

    public func setContentViewController(newVC: NSViewController) {
        let oldVC = self.contentViewController
        guard oldVC != newVC else {
            return
        }
        self.contentViewController = newVC

        addChildViewController(newVC)
        let newView = newVC.view
        let oldView = oldVC?.view
        view.addSubview(newView)
        if let oldView = oldView {
            oldView.removeFromSuperview()
        }
        oldVC?.removeFromParentViewController()

        newView.frame = view.bounds
        newView.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
    }

}
