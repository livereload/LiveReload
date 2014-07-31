import Foundation

operator infix <<< {}

@assignment @infix public func <<< <T>(inout lhs: [T], rhs: T) {
    lhs.append(rhs)
}

@assignment @infix public func += <K: Hashable, V>(inout lhs: [K: V], rhs: [K: V]) {
    for (key, value) in rhs {
        lhs[key] = value
    }
}
