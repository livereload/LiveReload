import Foundation

public class Coalescence {

    private enum State {
        case Idle
        case Scheduled
        case Running
        case RunningAndRequestedAgain
    }

    public typealias AsyncBlockType = (dispatch_block_t) -> Void
    public typealias MonitorBlockType = (Bool) -> Void

    public let delayMs: Int64
    public let serialQueue: dispatch_queue_t

    public var monitorBlock: MonitorBlockType = { (b) in }

    private var _state: State = .Idle

    public init(delayMs: Int64 = 0) {
        self.delayMs = delayMs
        self.serialQueue = dispatch_get_main_queue()
    }

    public func perform(block: dispatch_block_t) {
        performAsync({ (done) in block(); done() })
    }

    public func performAsync(block: AsyncBlockType) {
        switch (_state) {
        case .Idle:
            _schedule(block)
        case .Running:
            _state = .RunningAndRequestedAgain
        case .Scheduled:
            break;
        case .RunningAndRequestedAgain:
            break;
        }
        
    }

    private func _schedule(block: AsyncBlockType) {
        assert(_state == .Idle || _state == .RunningAndRequestedAgain)
        _state = .Scheduled

        monitorBlock(true)

        dispatch_after_ms(delayMs, queue: serialQueue) {
            assert(self._state == .Scheduled)
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
