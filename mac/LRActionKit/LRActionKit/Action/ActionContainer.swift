import Foundation

public protocol ActionContainer : NSObjectProtocol {

    var substitutionValues: [String: String] { get }
//    step.addValue(action.plugin.path as String, forSubstitutionKey: "plugin")

}
