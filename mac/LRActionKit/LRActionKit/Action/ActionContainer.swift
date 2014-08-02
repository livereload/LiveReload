import Foundation

@objc
public protocol ActionContainer : NSObjectProtocol, LRManifestErrorSink {

    var substitutionValues: [String: String] { get }

}
