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

    private override init() {
        super.init()
    }

}
