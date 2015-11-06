import Foundation
import ExpressiveFoundation

public protocol Processable: EmitterType {

    var isRunning: Bool { get }
    
}

public struct OperationDidStart: EventType {
    public let request: AnyRequestType
}

public struct OperationDidFinish: EventType {
    public let request: AnyRequestType
    public let error: ErrorType?
}

public struct ProcessableStateDidChange: EventType {
    public let isRunningChanged: Bool
}

public struct ProcessableBatchDidFinish: EventType {
}
