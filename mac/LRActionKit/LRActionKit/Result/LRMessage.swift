
import Foundation

public class LRMessage : NSObject, Printable {
    public let severity : LRMessageSeverity;
    public let text : String;
    public let filePath : String?;
    public let line: Int;
    public let column: Int;

    public var stack : String = "";
    public var rawOutput : String = "";

    public init(severity: LRMessageSeverity, text: String, filePath: String?, line: Int, column: Int) {
        self.severity = severity;
        self.text = text;
        self.filePath = filePath;
        self.line = line;
        self.column = column;
    }

    public override var description : String {
        let severityMessage = (severity == LRMessageSeverity.Error ? "Error" : "Warning")
        return "\(severityMessage) in \(filePath):\(line):\(column): \(text)"
    }
}
