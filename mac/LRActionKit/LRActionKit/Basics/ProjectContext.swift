import Foundation

@objc public protocol ProjectContext : NSObjectProtocol {

    var rootURL: NSURL { get }

    func hackhack_didWriteCompiledFile(file: ProjectFile)
    func hackhack_didFilterFile(file: ProjectFile)
    func hackhack_shouldFilterFile(file: ProjectFile) -> Bool

}
