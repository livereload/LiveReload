import Foundation

let NanosPerMillis: Int64 = 1000000

func dispatch_after_ms(delayMs: Int64, queue: dispatch_queue_t = dispatch_get_main_queue(), block: dispatch_block_t) {
    if delayMs > 0 {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayMs * NanosPerMillis), queue, block)
    } else {
        dispatch_async(queue, block)
    }
}

struct Coalescence {

    enum State {
        case Idle
        case Waiting
        case Running
        case RunningAndRequestedAgain
    }

    typealias AsyncBlockType = (dispatch_block_t) -> Void
    typealias MonitorBlockType = (Bool) -> Void

    let delayMs: Int64
    let serialQueue: dispatch_queue_t
    var monitorBlock: MonitorBlockType = { (b) in }

    var _state: State = .Idle

    init(delayMs: Int64 = 0) {
        self.delayMs = delayMs
        self.serialQueue = dispatch_get_main_queue()
    }

    mutating func performSync(block: dispatch_block_t) {
        perform({ (done) in block(); done() })
    }

    mutating func perform(block: AsyncBlockType) {
        switch (_state) {
        case .Idle:
            _schedule(block)
        case .Running:
            _state = .RunningAndRequestedAgain
        default:
            break;
        }
    }

    mutating func _schedule(block: AsyncBlockType) {
        _state = .Waiting

        monitorBlock(true)

        dispatch_after_ms(delayMs, queue: serialQueue) {
            assert(self._state == .Waiting)
            self._state = .Running

            block({
                dispatch_async(self.serialQueue) {
                    assert(self._state == .Running || self._state == .RunningAndRequestedAgain)
                    if self._state == .RunningAndRequestedAgain {
                        self._schedule(block)
                    } else {
                        self._state = .Idle
                        self.monitorBlock(false)
                    }
                }
            })
        }
    }

}

func coalesced<T: AnyObject>(delayMs: Int64 = 0, #serialQueue: dispatch_queue_t, weakSelf strong_weakSelf: T, #monitorBlock: ((T, Bool) -> Void), block: (T, dispatch_block_t) -> Void) -> dispatch_block_t {
    var requested: Bool = false
    var scheduled: Bool = false
    weak var weakSelf: T? = strong_weakSelf

    var schedule: dispatch_block_t!
    schedule = {
    }

    return {
        if !requested {
            requested = true
            schedule()
        }
    }
}

func coalesced<T: AnyObject>(delayMs: Int64 = 0, #weakSelf: T, #monitorBlock: (T, Bool) -> Void, block: (T, dispatch_block_t) -> Void) -> dispatch_block_t {
    return coalesced(delayMs: delayMs, serialQueue: dispatch_get_main_queue(), weakSelf: weakSelf, monitorBlock: monitorBlock, block)
}

func coalesced<T: AnyObject>(delayMs: Int64 = 0, #weakSelf: T, block: (T, dispatch_block_t) -> Void) -> dispatch_block_t {
    return coalesced(delayMs: delayMs, weakSelf: weakSelf, monitorBlock: { (a,b) in }, block)
}

func coalesced5<T: AnyObject>(delayMs: Int64 = 0, #weakSelf: T, block: (T, dispatch_block_t) -> Void) -> dispatch_block_t {
    return coalesced(delayMs: delayMs, weakSelf: weakSelf, monitorBlock: { (a,b) in }, block)
}

func coalesced<T: AnyObject>(delayMs: Int64 = 0, #serialQueue: dispatch_queue_t, #weakSelf: T, #monitorBlock: (T, Bool) -> Void, block: (T) -> Void) -> dispatch_block_t {
    return coalesced(delayMs: delayMs, serialQueue: serialQueue, weakSelf: weakSelf, monitorBlock: monitorBlock, { (host, done) in block(host); done() })
}

func coalesced<T: AnyObject>(delayMs: Int64 = 0, #weakSelf: T, #monitorBlock: (T, Bool) -> Void, block: (T) -> Void) -> dispatch_block_t {
    return coalesced(delayMs: delayMs, serialQueue: dispatch_get_main_queue(), weakSelf: weakSelf, monitorBlock: monitorBlock, block)
}

func coalesced<T: AnyObject>(delayMs: Int64 = 0, #weakSelf: T, block: (T) -> Void) -> dispatch_block_t {
    return coalesced(delayMs: delayMs, weakSelf: weakSelf, monitorBlock: { (a, b) in }, block)
}
