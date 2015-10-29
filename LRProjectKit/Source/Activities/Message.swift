import Foundation

public protocol MessageType {

}

public protocol ErrorMessageType: MessageType {

    var error: ErrorType { get }

    var isFailure: Bool { get }
    
}
