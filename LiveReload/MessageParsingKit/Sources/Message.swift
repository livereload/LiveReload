import Foundation

public enum MessageSeverity {
    
    case Raw
    
    case Error
    
    case Warning
    
}

public struct Message {
    
    public var severity: MessageSeverity
    
    public var text: String?
    
    public var file: String?
    
    public var line: Int?
    
    public var column: Int?
    
    public var stack: String?
    
    public init(severity: MessageSeverity, text: String?, file: String? = nil, line: Int? = nil) {
        self.severity = severity
        self.text = text
        self.file = file
        self.line = line
    }
    
    public init(severity: MessageSeverity, fieldValues: [MessageField: String]) {
        self.severity = severity
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

extension Message: CustomStringConvertible {
    
    public var lineColumnDescription: String? {
        if let line = line {
            if let column = column {
                return "\(line):\(column)"
            } else {
                return "\(line)"
            }
        } else {
            return nil
        }
    }
    
    public var locationDescription: String? {
        if let file = file {
            if let loc = lineColumnDescription {
                return "\(file):\(loc)"
            } else {
                return "\(file)"
            }
        } else if let loc = lineColumnDescription {
            return "\(loc)"
        } else {
            return nil
        }
    }
    
    public var description: String {
        let locationPart: String
        if let loc = locationDescription {
            locationPart = " in \(loc)"
        } else {
            locationPart = ""
        }
        
        if let text = text {
            return "\(severity)\(locationPart): \(text)"
        } else {
            return "\(severity)\(locationPart)"
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
