import Foundation

public protocol Dispatcher: class {

    public func execute(operation: Operation)

}

public protocol Operation: class {

    public func execute() {

    }

}
