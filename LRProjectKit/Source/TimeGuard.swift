import Foundation

public class TimeGuardCategory {

    public let name: String
    public let redThreshold: NSTimeInterval

    public init(name: String, redThreshold: NSTimeInterval) {
        self.name = name
        self.redThreshold = redThreshold
    }

}

public class TimeGuard {

    public let category: TimeGuardCategory

    private let startTime = NSDate.timeIntervalSinceReferenceDate()

    private var finished = false

    public init(_ category: TimeGuardCategory) {
        self.category = category
    }

    public func finish() {
        guard !finished else {
            fatalError("Duplicate call to TimeGuard.finish")
        }
        finished = true

        let endTime = NSDate.timeIntervalSinceReferenceDate()
        let elapsed = endTime - startTime
        print("\(category.name): \(elapsed) seconds")
    }

}