import Foundation
import LRActionKit

public enum ToolOutputType{
    case Log
    case Error
    case ErrorRaw
}

public class ToolOutput: NSObject {

    public let action: Action
    public let type: ToolOutputType
    public let sourcePath: String?
    public let line: Int?
    public let message: String?
    public let output: String?

    public init(action: Action, type: ToolOutputType, sourcePath: String?, line: Int?, message: String?, output: String?) {
        self.action = action
        self.type = type
        self.sourcePath = sourcePath
        self.line = line
        self.message = message
        self.output = output
        super.init()
    }
    
}
