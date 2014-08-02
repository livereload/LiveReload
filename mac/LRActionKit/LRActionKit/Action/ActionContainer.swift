import Foundation

@objc
public protocol ActionContainer : NSObjectProtocol, LRManifestErrorSink {

    var substitutionValues: [String: String] { get }
//    step.addValue(action.plugin.path as String, forSubstitutionKey: "plugin")

}
