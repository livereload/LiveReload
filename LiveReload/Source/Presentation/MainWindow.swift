import Cocoa

public class MainWindow: NSWindow {

    public static let didChangeFirstResponder = "\(MainWindow.self).didChangeFirstResponder"

    public override func makeFirstResponder(aResponder: NSResponder?) -> Bool {
        let result = super.makeFirstResponder(aResponder)
        if result {
            NSNotificationCenter.defaultCenter()
                .postNotificationName(MainWindow.didChangeFirstResponder, object: self)
        }
        return result
    }

}
