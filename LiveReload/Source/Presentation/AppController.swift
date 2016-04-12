import Cocoa

public class AppController {

    public let app: App

    public init(app: App) {
        self.app = app
    }


    // MARK: - Main Window

    private var _mainWindowController: MainWindowController?

    private var mainWindowController: MainWindowController {
        if let wc = _mainWindowController {
            return wc
        }
        let sb = NSStoryboard(name: "MainWindow", bundle: nil)
        let wc = sb.instantiateControllerWithIdentifier("MainWindow") as! MainWindowController
        wc.setup(self)
        _mainWindowController = wc
        return wc
    }

    public func showMainWindow() {
        mainWindowController.showWindow(nil)
    }

}
