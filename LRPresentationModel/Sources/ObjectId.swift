import Foundation

public struct ObjectId {

    public let key: String

    public init(_ key: String) {
        self.key = key
    }

    public convenience init() {
        self.init(NSUUID().UUIDString)
    }

}

extension ObjectId: Hashable {
    public var hashValue: Int {
        return key.hashValue
    }
}

public func ==(lhs: ObjectId, rhs: ObjectId) -> Bool {
    return (lhs.key == rhs.key)
}
