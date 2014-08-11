import Foundation

private let NanosPerMillis: Int64 = 1_000_000

public func dispatch_after_ms(delayMs: Int64, queue: dispatch_queue_t = dispatch_get_main_queue(), block: dispatch_block_t) {
    if delayMs > 0 {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayMs * NanosPerMillis), queue, block)
    } else {
        dispatch_async(queue, block)
    }
}

public func dispatch_after_s(delay: NSTimeInterval, queue: dispatch_queue_t = dispatch_get_main_queue(), block: dispatch_block_t) {
    if delay > -1e-8 {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(delay) * Double(NanosPerMillis) * 1000.0)), queue, block)
    } else {
        dispatch_async(queue, block)
    }
}
