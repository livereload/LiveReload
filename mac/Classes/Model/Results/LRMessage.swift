
import Foundation

@objc class LRMessage : NSObject, Printable {
    let severity : LRMessageSeverity;
    let text : String;
    let filePath : String?;
    let line: Int;
    let column: Int;

    var stack : String = "";
    var rawOutput : String = "";

    init(severity: LRMessageSeverity, text: String, filePath: String?, line: Int, column: Int) {
        self.severity = severity;
        self.text = text;
        self.filePath = filePath;
        self.line = line;
        self.column = column;
    }

    override var description : String {
        let severityMessage = (severity == LRMessageSeverity.Error ? "Error" : "Warning")
        return "\(severityMessage) in \(filePath):\(line):\(column): \(text)"
    }
}
