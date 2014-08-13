import Cocoa
import SwiftyFoundation

struct EmailSignupData {

    let name: String
    let email: String

}

class EmailSignupWindow: NSWindowController, NSTextFieldDelegate {

    @IBOutlet weak var emailField: NSTextField!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var okButton: NSButton!

    override func windowDidLoad() {
        super.windowDidLoad()
        updateButton()
    }

    override func controlTextDidChange(obj: NSNotification) {
        updateButton()
    }

    func extractData() -> EmailSignupData {
        let name = nameField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        let email = emailField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return EmailSignupData(name: name, email: email)
    }

    func updateButton() {
        let data = extractData()
        let valid = !data.name.isEmpty && !data.email.isEmpty
        okButton.enabled = valid
    }

    @IBAction func performOK(sender: NSButton) {
        let data = extractData()
        sendSecureMessageToAppOwner("livereload-3-beta", <#body: NSString#>)
    }
    
}
