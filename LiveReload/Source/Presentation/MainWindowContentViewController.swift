import Cocoa

public class MainWindowContentViewController: NSSplitViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()
        print("\(self.dynamicType).viewDidLoad")
    }

}
