import Foundation

@objc public protocol ProjectContext : NSObjectProtocol {

    var rootURL: NSURL { get }

    func hackhack_didWriteCompiledFile(file: LRProjectFile)
    func hackhack_didFilterFile(file: LRProjectFile)
    func hackhack_shouldFilterFile(file: LRProjectFile) -> Bool

}
