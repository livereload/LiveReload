import Foundation

infix operator <<< {}

public func <<< <T>(inout lhs: [T], rhs: T) {
    lhs.append(rhs)
}

public func += <K: Hashable, V>(inout lhs: [K: V], rhs: [K: V]) {
    for (key, value) in rhs {
        lhs[key] = value
    }
}
