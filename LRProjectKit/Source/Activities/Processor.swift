import Foundation
import ExpressiveFoundation
import PromiseKit

public protocol OperationContext {

    func emit(message: MessageType)

}

public class Operation<Request: RequestType>: OperationContext {

    public private(set) var request: Request

    private var promise: Promise<Void>!

    private init(request: Request) {
        self.request = request
    }

    public func emit(message: MessageType) {

    }

}

/// There are two cases when an operation would not be running, but pending requests
/// would be non-empty and `isRunning` would return `true`:
///
/// (1) while waiting for the next run loop iteration to start the first operation
/// of a batch;
///
/// (2) while waiting for an execution strategy to be set during the initialization phase.
///
public class Processor<Request: RequestType>: Processable {

    public var _listeners = EventListenerStorage()

    public private(set) var runningOperation: Operation<Request>?
    public private(set) var lastRequest: Request?
    public private(set) var lastError: ErrorType?
    public private(set) var pendingRequests: [Request] = []
    public private(set) var isRunning: Bool = false

}

public class ProcessorImpl<Request: RequestType>: Processor<Request> {

    public typealias StrategyBlock = (Request, OperationContext) -> Promise<Void>

    private var block: StrategyBlock?

    public private(set) var disposed: Bool = false

    public init(block: StrategyBlock? = nil) {
        self.block = block
    }

    public func setStrategy(block: StrategyBlock) {
        if self.block != nil {
            fatalError("Can only set Processor block once")
        }
        self.block = block
        scheduleStartSoonIfNeeded()
    }

    public func setStrategy<Host: AnyObject>(host: Host, _ block: (Host) -> (Request, OperationContext) -> Promise<Void>) {
        setStrategy { [weak host] (request, context) in
            if let host = host {
                return block(host)(request, context)
            } else {
                return Promise(())
            }
        }
    }

    public func dispose() {
        disposed = true
        pendingRequests = []
    }

    public func schedule(newRequest: Request) {
        if let op = runningOperation {
            if let merged = Request.merge(op.request, newRequest, isRunning: true) {
                op.request = merged
                return
            }
        }
        addPendingRequest(newRequest)
        scheduleStartSoonIfNeeded()
    }

    private func addPendingRequest(request: Request) {
        for (idx, pending) in pendingRequests.enumerate() {
            if let merged = Request.merge(pending, request, isRunning: false) {
                pendingRequests[idx] = merged
                return
            }
        }
        pendingRequests.append(request)
    }

    private func scheduleStartSoonIfNeeded() {
        guard block != nil else {
            return
        }
        guard !pendingRequests.isEmpty else {
            return
        }
        guard !isRunning else {
            return
        }

        isRunning = true
        emit(ProcessableStateDidChange(isRunningChanged: true))
        #if true
            print("\(self): batch started")
        #endif

        dispatch_async(dispatch_get_main_queue()) {
            self.startNextRequestOrEndBatch()
        }
    }

    private func startNextRequestOrEndBatch() {
        if pendingRequests.isEmpty {
            didEndBatch()
        } else {
            startOperation(Operation(request: pendingRequests.removeFirst()))
        }
    }

    private func startOperation(operation: Operation<Request>) {
        guard let block = block else {
            fatalError()
        }

        runningOperation = operation

        #if true
            print("\(self): starting operation for \(operation.request)")
        #endif

        emit(ProcessableStateDidChange(isRunningChanged: false))
        emit(OperationDidStart(request: operation.request))

        let promise = block(operation.request, operation)
        operation.promise = promise
        promise.then {
            self.didFinish(operation, error: nil)
        }
        promise.error(policy: .AllErrors) { err in
            self.didFinish(operation, error: err)
        }
    }

    private func didFinish(operation: Operation<Request>, error: ErrorType?) {
        lastError = error
        lastRequest = operation.request
        emit(OperationDidFinish(request: operation.request))
        startNextRequestOrEndBatch()
    }

    private func didEndBatch() {
        guard runningOperation != nil else {
            return
        }
        #if true
            print("\(self): update finished")
        #endif
        runningOperation = nil
        isRunning = false
        emit(ProcessableStateDidChange(isRunningChanged: true))
        emit(ProcessableBatchDidFinish())
    }

}
