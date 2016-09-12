import Foundation
import ExpressiveFoundation
import PromiseKit
import EditorKit

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

public enum ProcessorError: ErrorType {

    case ProcessorDisposed

}

/// There are two cases when an operation would not be running, but pending requests
/// would be non-empty and `isRunning` would return `true`:
///
/// (1) while waiting for the next run loop iteration to start the first operation
/// of a batch;
///
/// (2) while waiting for an execution strategy to be set during the initialization phase.
///
public class Processor<Request: RequestType>: Processable, StdEmitterType {

    public var _listeners = EventListenerStorage()

    public private(set) var runningOperation: Operation<Request>?
    public private(set) var lastRequest: Request?
    public private(set) var lastError: ErrorType?
    public private(set) var pendingRequests: [Request] = []
    public private(set) var isRunning: Bool = false

}

public class ProcessorImpl<Request: RequestType>: Processor<Request>, CustomStringConvertible {

    private var emitsEventsOnHost: Bool = false

    private weak var host: EmitterType?

    private var block: ((AnyObject, Request, OperationContext) -> Promise<Void>)?

    public private(set) var disposed: Bool = false

    private(set) var isActuallyScheduledOrRunning: Bool = false

    public func initializeWithHost<Host: EmitterType>(host: Host, emitsEventsOnHost: Bool, performs performMethod: (Host) -> (Request, OperationContext) -> Promise<Void>) {
        if self.block != nil {
            fatalError("Can only invoke initializeWithHost once")
        }
        self.host = host
        self.block = { (host, request, context) in
            return performMethod(host as! Host)(request, context)
        }
        self.emitsEventsOnHost = emitsEventsOnHost
        scheduleStartSoonIfNeeded()
    }

    public var description: String {
        if let host = host {
            return "\(String(reflecting: host)):Processor"
        } else {
            return "Processor"
        }
    }

    public func emit(event: EventType) {
        _emitHere(event)
        if emitsEventsOnHost, let host = host {
            host.emit(event)
        }
    }

    public func dispose() {
        disposed = true
        scheduleStartSoonIfNeeded()
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
        guard !pendingRequests.isEmpty else {
            return
        }

        if !isRunning {
            isRunning = true
            emit(ProcessableStateDidChange(isRunningChanged: true))
            #if true
                print("\(self): batch started")
            #endif
        }

        if !isActuallyScheduledOrRunning && ((block != nil) || disposed) {
            isActuallyScheduledOrRunning = true
            dispatch_async(dispatch_get_main_queue()) {
                self.startNextRequestOrEndBatch()
            }
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
        runningOperation = operation

        #if true
            print("\(self): starting operation for \(operation.request)")
        #endif

        emit(ProcessableStateDidChange(isRunningChanged: false))
        emit(OperationDidStart(request: operation.request))

        let promise: Promise<Void>
        if !disposed, let host = host {
            guard let block = block else {
                fatalError()
            }
            promise = block(host, operation.request, operation)
        } else {
            promise = Promise(error: ProcessorError.ProcessorDisposed)
        }
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
        emit(OperationDidFinish(request: operation.request, error: error))
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
        isActuallyScheduledOrRunning = false
        emit(ProcessableStateDidChange(isRunningChanged: true))
        emit(ProcessableBatchDidFinish())
    }

}
