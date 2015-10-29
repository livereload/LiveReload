import Foundation

public protocol RequestType: Equatable {

    func merge(other: Self, isRunning: Bool) -> Self?

}

public extension RequestType {

    public static func merge(a: Self, _ b: Self, isRunning: Bool) -> Self? {
        if a == b {
            return a
        } else if let c = a.merge(b, isRunning: isRunning) {
            return c
        } else if let c = b.merge(a, isRunning: isRunning) {
            return c
        } else {
            return nil
        }
    }
    
}
