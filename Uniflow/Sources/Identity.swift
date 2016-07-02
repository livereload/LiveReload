//import Foundation
//
//// immutable & unique
//public protocol Identity: class {
////    var tags: [Tag] { get }
//}
//
//public extension Identity {
//
//    public var hashValue: Int {
//        return ObjectIdentifier(self).hashValue
//    }
//
//}
//
//public func ==(lhs: Identity, rhs: Identity) -> Bool {
//    return lhs === rhs
//}
//
//public class SimpleIdentity: Identity, Hashable {
//
//    public let tag: Tag
//
//    public init(_ tag: Tag) {
//        self.tag = tag
//    }
//
//}
//
//public func ==(lhs: SimpleIdentity, rhs: SimpleIdentity) -> Bool {
//    return lhs === rhs
//}
//
