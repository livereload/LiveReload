import Cocoa
import SwiftyFoundation

public class EmailSignupWindow: NSWindowController, NSTextFieldDelegate {

    @IBOutlet weak var emailField: NSTextField!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var aboutField: NSTextField!
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    public class func create() -> EmailSignupWindow {
        return EmailSignupWindow(windowNibName: "EmailSignupWindow")
    }

    override public func windowDidLoad() {
        super.windowDidLoad()
        self.window!.center()

        let data = MarketingCommunication.instance.loadPreviousBetaSignupData()
        emailField.stringValue = data.email
        nameField.stringValue = data.name
        aboutField.stringValue = data.about

        updateButton()
    }

    override public func controlTextDidChange(obj: NSNotification) {
        updateButton()
    }

    private func extractData() -> BetaSignupData {
        let name = nameField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        let email = emailField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        let about = aboutField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return BetaSignupData(name: name, email: email, about: about)
    }

    private func updateButton() {
        let data = extractData()
        let valid = !data.name.isEmpty && !data.email.isEmpty && isValidEmail(data.email)
        okButton.enabled = valid
    }

    public func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        if control === aboutField {
            if commandSelector == Selector("insertNewline:") {
                textView.insertNewlineIgnoringFieldEditor(self)
                return true
            }
        }
        return false
    }

    private func isValidEmail(email: String) -> Bool {
        let range = email.rangeOfString("@", options: nil, range: nil, locale: nil)
        return range != nil
    }

    @IBAction public func performOK(sender: AnyObject) {
        let data = extractData()

        let originalLabel = okButton.title
        okButton.title = "Sending..."
        okButton.enabled = false
        progressIndicator.startAnimation(self)
        MarketingCommunication.instance.sendBetaSignup(data) { error in
            self.progressIndicator.stopAnimation(self)
            if let error = error {
                self.okButton.title = originalLabel
                self.okButton.enabled = true

                let alert = NSAlert()
                alert.messageText = "Sending failed"
                alert.informativeText = error.localizedDescription
                alert.addButtonWithTitle("Retry")
                alert.addButtonWithTitle("Skip")
                alert.beginSheetModalForWindow(self.window!, completionHandler: { response in
                    if response == NSAlertFirstButtonReturn {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.performOK(sender)
                        }
                    } else {
                        self.close()
                    }
                })
            } else {
                self.okButton.title = "✓ Sent, thank you!"
                dispatch_after_ms(1000) {
                    self.close()
                }
            }
        }
    }

}
