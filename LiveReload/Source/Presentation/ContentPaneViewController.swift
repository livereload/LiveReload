import Cocoa

public class ContentPaneViewController: NSViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()
        print("\(self.dynamicType).viewDidLoad")
    }

    public func setup(appController: AppController) {
        print("\(self.dynamicType).setup")
    }

}
