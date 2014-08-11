import Foundation
import SwiftyFoundation


@objc
public protocol OptionProtocol : NSObjectProtocol {

    var identifier: String { get }

}

@objc
public protocol TextOptionProtocol : OptionProtocol {

    var label: String { get }
    var placeholder: String? { get }

    var effectiveValue: String { get set }

}

@objc
public protocol BooleanOptionProtocol : OptionProtocol {

    var label: String { get }

    var effectiveValue: Bool { get set }

}

@objc
public class MultipleChoiceOptionItem : NSObject {

    public let identifier: String
    public let label: String
    public let index: Int
    public let arguments: [String]

    public init(identifier: String, label: String, index: Int, arguments: [String]) {
        self.identifier = identifier
        self.label = label
        self.index = index
        self.arguments = arguments
    }

}

@objc
public protocol MultipleChoiceOptionProtocol : OptionProtocol {

    var label: String { get }

    var items: [MultipleChoiceOptionItem] { get }
    var unknownItem: MultipleChoiceOptionItem? { get }

    var effectiveItem: MultipleChoiceOptionItem { get set }

}
