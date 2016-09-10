import Foundation

// based on https://gist.github.com/calebd/93fa347397cec5f88233

public class ConcurrentOperation: NSOperation {

    private enum State {
        case Idle
        case Executing
        case Finished
    }

    private var state: State = .Idle

    public override var executing: Bool {
        return state == .Executing
    }
    public override var finished: Bool {
        return state == .Finished
    }
    public override var asynchronous: Bool {
        return true
    }

    public override func start() {
        if self.cancelled {
            didFinish()
        } else {
            willChangeValueForKey("isExecuting")
            state = .Executing
            didChangeValueForKey("isExecuting")

            main()
        }
    }

    public func didFinish() {
        willChangeValueForKey("isExecuting")
        willChangeValueForKey("isFinished")
        state = .Finished
        didChangeValueForKey("isExecuting")
        didChangeValueForKey("isFinished")
    }

}
