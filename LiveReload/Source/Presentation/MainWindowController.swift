import Cocoa

public class MainWindowController: NSWindowController {

    public weak var delegate: MainWindowControllerDelegate?

    private var app: App!

    private let splitVC = NSSplitViewController()
    private let treePaneVC = TreePaneViewController()
    private let contentPaneVC = ContentPaneViewController()

    private let treePaneItem: NSSplitViewItem
    private let contentPaneItem: NSSplitViewItem

    public init() {
        treePaneItem = NSSplitViewItem(sidebarWithViewController: treePaneVC)
        contentPaneItem = NSSplitViewItem(viewController: contentPaneVC)

        super.init(window: nil)

        splitVC.splitViewItems = [treePaneItem, contentPaneItem]
    }

    public override var windowNibName: String? {
        // This method must return a non-nil value, otherwise loadWindow won't be called.
        // See http://www.openradar.me/19289232: “NSWindowController subclasses must override
        // windowNibName for programmatically created windows”.
        return "non-nil"
    }

    public override func loadWindow() {
        let style: Int = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
        let window = MainWindow(contentRect: NSRect.zero, styleMask: style, backing: .Buffered, defer: false)

        window.collectionBehavior = [.MoveToActiveSpace, .Managed, .FullScreenAuxiliary, .FullScreenAllowsTiling]

        self.window = window
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setup(appController: AppController) {
        print("\(self.dynamicType).setup")
        app = appController.app
        treePaneVC.setup(appController)
        contentPaneVC.setup(appController)
    }

    public override func windowDidLoad() {
        // TODO: What's the right way to pick the screen? mainScreen vs screens()[0] vs ...?
        let screen = NSScreen.mainScreen()!
        let screenFrame = screen.frame
        let size = CGSize(width: round(screenFrame.width * (2/3)), height: round(screenFrame.height * (2/3)))

        let window = self.window!
        window.contentViewController = splitVC

        window.title = NSLocalizedString("LiveReload", comment: "App Title")

        // Setting contentViewController resets the frame, so this needs to come after it.
        window.setFrame(NSRect(origin: .zero, size: size), display: false, animate: false)
        window.center()
    }

}



// MARK: - Delegate

public protocol MainWindowControllerDelegate: class {


}
