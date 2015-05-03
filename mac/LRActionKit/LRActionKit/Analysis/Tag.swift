import Foundation
import VariableKit
import ATPathSpec

public final class Tag: Printable {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public var description: String {
        return "#\(name)"
    }
}

public struct TagEvidence: Printable {
    public let tag: Tag
    // public let source: TagSource
    // public let priority: Int
    // public let reason: String
    
    // , source: TagSource, priority: Int = 0, reason: String
    public init(tag: Tag) {
        self.tag = tag
        // self.source = source
        // self.priority = priority
        // self.reason = reason
    }
    
    public var description: String {
        return "\(tag)"
    }
}
