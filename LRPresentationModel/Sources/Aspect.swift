import Foundation

public class Aspect {

    public let tag: Tag
    public let name: String

    public init(_ tag: Tag, _ name: String) {
        self.tag = tag
        self.name = name
    }

}

extension Aspect: Hashable {

    public var hashValue: Int {
        return tag.hashValue ^ name.hashValue
    }

}

public func ==(lhs: Aspect, rhs: Aspect) -> Bool {
    return (lhs.tag == rhs.tag) && (lhs.name == rhs.name)
}
