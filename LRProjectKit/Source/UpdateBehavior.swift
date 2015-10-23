import Foundation
import ExpressiveFoundation

public protocol UpdateRequestType: Equatable {

    func merge(other: Self) -> Self?

}

public extension UpdateRequestType {

    public static func merge(a: Self, _ b: Self) -> Self? {
        if a == b {
            return a
        } else if let c = a.merge(b) {
            return c
        } else if let c = b.merge(a) {
            return c
        } else {
            return nil
        }
    }

}

public enum StdUpdateReason: Int, UpdateRequestType {

    case Initial
    case Periodic
    case ExternalChange
    case UserInitiated

    public func merge(other: StdUpdateReason) -> StdUpdateReason? {
        if other.rawValue > self.rawValue {
            return other
        } else {
            return self
        }
    }

}

public struct UpdateBatchDidStart: EventType {
}
public struct UpdateDidFinish<UpdateRequest: UpdateRequestType>: EventType {
    public let request: UpdateRequest
}
public struct UpdateBatchDidFinish: EventType {
}

public struct UpdateBehavior<Owner: EmitterType, UpdateRequest: UpdateRequestType> {

    public unowned var owner: Owner
    public let updateMethod: (Owner) -> () -> Void
    public let endBatchMethod: ((Owner) -> () -> Void)?

    public private(set) var runningRequest: UpdateRequest?
    public private(set) var lastRequest: UpdateRequest?
    public private(set) var lastError: ErrorType?
    public private(set) var pendingRequests: [UpdateRequest] = []

    public var isUpdating: Bool {
        return runningRequest != nil
    }

    public init(_ owner: Owner, _ updateMethod: (Owner) -> () -> Void, endBatchMethod: ((Owner) -> () -> Void)? = nil) {
        self.owner = owner
        self.updateMethod = updateMethod
        self.endBatchMethod = endBatchMethod
    }

    public mutating func update(request: UpdateRequest) {
        if let current = runningRequest {
            if let merged = UpdateRequest.merge(current, request) {
                self.runningRequest = merged
            } else {
                addPendingRequest(request)
            }
        } else {
            didStartBatch()
            startUpdate(request)
        }
    }

    private mutating func addPendingRequest(request: UpdateRequest) {
        for (idx, pending) in pendingRequests.enumerate() {
            if let merged = UpdateRequest.merge(pending, request) {
                pendingRequests[idx] = merged
                return
            }
        }
        pendingRequests.append(request)
    }

    private mutating func startUpdate(request: UpdateRequest) {
        runningRequest = request
        updateMethod(owner)()
    }

    private mutating func startNextRequest() {
        if pendingRequests.isEmpty {
            didEndBatch()
        } else {
            startUpdate(pendingRequests.removeFirst())
        }
    }

    public mutating func didSucceed() {
        lastError = nil
        didFinish()
    }

    public mutating func didFail(error: ErrorType) {
        lastError = error
        didFinish()
    }

    private mutating func didFinish() {
        lastRequest = runningRequest
        runningRequest = nil
        owner.emit(UpdateDidFinish(request: lastRequest!))
        startNextRequest()
    }

    private mutating func didStartBatch() {
        owner.emit(UpdateBatchDidStart())
    }

    private mutating func didEndBatch() {
        runningRequest = nil
        owner.emit(UpdateBatchDidFinish())
    }

}
