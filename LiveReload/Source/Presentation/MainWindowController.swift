import Cocoa

public class MainWindowController: NSWindowController {

    public weak var delegate: MainWindowControllerDelegate?

    private let splitVC = NSSplitViewController()
    private let treePaneVC = TreePaneViewController()
    private let contentPaneVC = ContentPaneViewController()

    private let treePaneItem: NSSplitViewItem
    private let contentPaneItem: NSSplitViewItem

//    public override init() {
//        fatalError("Duh")
//
//        let screen = NSScreen.mainScreen()!
//        let screenFrame = screen.frame
//        let size = CGSize(width: round(screenFrame.width * (2/3)), height: round(screenFrame.height * (2/3)))
//
//        let style: Int = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
//        let window = MainWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: style, backing: .Buffered, defer: false)
//
//        window.minSize = NSSize(width: 100, height: 100)
//        window.opaque = false

//        super.init()

//        window.center()
//]
//        super.init(windowNibName: ")
//    }

    public override init(window: NSWindow?) {
        fatalError("Must instantiate from a storyboard")
    }

    public required init?(coder aDecoder: NSCoder) {
        treePaneItem = NSSplitViewItem(sidebarWithViewController: treePaneVC)
        contentPaneItem = NSSplitViewItem(viewController: contentPaneVC)

        super.init(coder: aDecoder)

        splitVC.splitViewItems = [treePaneItem, contentPaneItem]
    }

    public override func windowDidLoad() {
        let window = self.window!
        window.contentViewController = splitVC
        window.title = NSLocalizedString("LiveReload", comment: "App Title")
    }

//    public override func showWindow(sender: AnyObject?) {
//        window!.makeKeyAndOrderFront(sender)
//    }

}



// MARK: - Delegate

public protocol MainWindowControllerDelegate: class {


}
