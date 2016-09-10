import Foundation

public protocol Identity: CustomStringConvertible {
    
    func isEqualTo(other: Identity) -> Bool

    var hashValue: Int { get }
    
}

public extension Identity where Self: Equatable {
    
    public func isEqualTo(other: Identity) -> Bool {
        if other.dynamicType == Self.self {
            return self == (other as! Self)
        } else {
            return false
        }
    }

}

public func ==(lhs: Identity, rhs: Identity) -> Bool {
    return lhs.isEqualTo(rhs)
}


/// A box for putting identities in collections
public struct AnyIdentity: Hashable {
    
    public let identity: Identity

    public init(identity: Identity) {
        self.identity = identity
    }
    
    public var hashValue: Int {
        return identity.hashValue
    }
    
}

public func ==(lhs: AnyIdentity, rhs: AnyIdentity) -> Bool {
    return lhs.identity == rhs.identity
}


public struct StringIdentity: Identity {
    
    public let name: String
    
    public init(_ name: String) {
        self.name = name
    }

    public var description: String {
        return name
    }
   
}

extension StringIdentity: Hashable {
    public var hashValue: Int {
        return name.hashValue
    }
}

public func ==(lhs: StringIdentity, rhs: StringIdentity) -> Bool {
    return (lhs.name == rhs.name)
}
