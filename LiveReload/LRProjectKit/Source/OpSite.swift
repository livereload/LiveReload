import Foundation

public protocol OpSite: class {

    var isRunning: Bool { get }

    func started()

    func succeeded()

    func failed(error: ErrorType)

    func interrupted()

}
