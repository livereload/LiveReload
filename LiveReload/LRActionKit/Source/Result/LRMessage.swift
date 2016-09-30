import Foundation
import MessageParsingKit

public class LRMessage : NSObject {
    
    public let message: Message

    public init(_ message: Message) {
        self.message = message
    }

    public override var description : String {
        return message.description
    }
    
    public var severity: MessageSeverity {
        return message.severity
    }

}
