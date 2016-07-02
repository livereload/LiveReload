import Foundation

// immutable & unique
public protocol Identity: class {

//    var tags: [Tag] { get }

}

public extension Identity {

    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

}

public func ==(lhs: Identity, rhs: Identity) -> Bool {
    return lhs === rhs
}

public class SimpleIdentity: Identity {

    public let tags: [Tag]

    public init(tags: [Tag]) {
        self.tags = tags
    }

}

public protocol Identifiable {

    var identity: Identity { get }
    
}
