import Foundation

// Replacement for performSelector:afterDelay: and cancelPreviousPerformSelectorRequests.
//
// * Runs the given block asynchronously, with or without delay.
// * Can be cancelled.
// * Automatically cancels all previous invocations.
//
public class Delayed {
    private typealias RequestId = Int64

    private var lastRequestId: RequestId = 0

    public init() {
    }

    deinit {
        cancel()
    }

    public func cancel() {
        ++lastRequestId
    }

    public func perform(block: dispatch_block_t) {
        let requestId = ++lastRequestId

        dispatch_async(dispatch_get_main_queue()) {
            if self.lastRequestId == requestId {
                block()
            }
        }
    }

    public func performAfterDelay(delay: NSTimeInterval, _ block: dispatch_block_t) {
        let requestId = ++lastRequestId

        dispatch_after_s(delay, queue: dispatch_get_main_queue()) {
            if self.lastRequestId == requestId {
                block()
            }
        }
    }
}
