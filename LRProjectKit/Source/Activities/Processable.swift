import Foundation
import ExpressiveFoundation

public protocol Processable: EmitterType {

    var isRunning: Bool { get }
    
}

public struct OperationDidStart<Request: RequestType>: EventType {
    public let request: Request
}

public struct OperationDidFinish<Request: RequestType>: EventType {
    public let request: Request
}

public struct ProcessableStateDidChange: EventType {
    public let isRunningChanged: Bool
}

public struct ProcessableBatchDidFinish: EventType {
}
