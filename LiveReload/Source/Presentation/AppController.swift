import Cocoa
import LRProjectKit

public class AppController {

    public let app: App

    public init(app: App) {
        self.app = app
    }


    // MARK: - Main Window

    private var isMainWindowControllerLoaded = false

    private lazy var mainWindowController: MainWindowController = { [unowned self] in
        self.isMainWindowControllerLoaded = true
        let wc = MainWindowController(app: self.app)
        wc.delegate = self
        return wc
    }()

    public var isMainWindowVisible: Bool {
        return isMainWindowControllerLoaded && mainWindowController.windowLoaded && mainWindowController.window!.visible
    }

    public func showMainWindow() {
        mainWindowController.showWindow(nil)
    }

}

extension AppController: MainWindowControllerDelegate {

    public func newContentViewControllerForProject(project: Project) -> ProjectPaneViewController {
        return ProjectPaneViewController(project: project)
    }

}
