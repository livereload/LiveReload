import Foundation
import PackageManagerKit
import ExpressiveCasting

@objc
public final class ActionKitSingleton: NSObject {

    public static let sharedActionKit = ActionKitSingleton()

    public let optionRegistry: OptionRegistry = ({
        let or = OptionRegistry()
        or.addOptionType(CheckboxOptionType())
        or.addOptionType(MultipleChoiceOptionType())
        or.addOptionType(TextOptionType())
        return or
    })()

    public var packageManager: LRPackageManager!

    public var postMessageBlock: (message: JSONObject, completionBlock: (error: NSError?, response: JSONObject?) -> Void) -> Void

    private override init() {
        postMessageBlock = { message, completionBlock in
            fatalError("postMessageBlock not set, sending message \(message)")
        }

        super.init()
    }

    public func postMessage(message: JSONObject, completionBlock: (error: NSError?, response: JSONObject?) -> Void) {
        postMessageBlock(message: message, completionBlock: completionBlock)
    }

}
