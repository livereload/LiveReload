import Foundation

public class Tag {

    public static let root = Tag("<root>")

    public let name: String
    
    public let changeNotificationName: String

    public init(_ name: String) {
        self.name = name
        changeNotificationName = "\(name).didChange"
    }

}

extension Tag: CustomStringConvertible {
    public var description: String {
        return name
    }
}

extension Tag: Hashable {
    public var hashValue: Int {
        return name.hashValue
    }
}

public func ==(lhs: Tag, rhs: Tag) -> Bool {
    return (lhs.name == rhs.name)
}
