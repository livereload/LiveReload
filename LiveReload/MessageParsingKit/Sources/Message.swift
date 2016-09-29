import Foundation

public struct Message {
    
    public var text: String?
    
    public var file: String?
    
    public var line: Int?
    
    public var column: Int?
    
    public init(text: String?) {
        self.text = text
    }
    
    public init(fieldValues: [MessageField: String]) {
        self.text = fieldValues[.Message]
        self.file = fieldValues[.File]
        if let s = fieldValues[.Line], v = Int(s, radix: 10) {
            self.line = v
        }
        if let s = fieldValues[.Column], v = Int(s, radix: 10) {
            self.column = v
        }
    }
    
}

public enum MessageField: String {
    case Message = "message"
    case File = "file"
    case Line = "line"
    case Column = "column"
    
    public static func from(name name: String) -> MessageField? {
        switch name {
        case "message": return .Message
        case "file":    return .File
        case "line":    return .Line
        case "column":  return .Column
        default:        return nil
        }
    }
    
    internal var defaultRegexp: String {
        switch self {
        case .Message:  return "\\S[^\\n]+?"
        case .File:     return "[^\\n]+?"
        case .Line:     return "\\d+"
        case .Column:   return "\\d+"
        }
    }
}
