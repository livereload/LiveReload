import Foundation
import ExpressiveCasting
import ExpressiveCollections

public class LRActionManifest : LRManifestBasedObject {

    public let layers: [LRManifestLayer]

    // public let identifier: String
    // public let name: String

    public let optionSpecs: [OptionSpec]

    public let errorSpecs: [AnyObject]
    public let warningSpecs: [AnyObject]

    public let commandLineSpec: [String]?
    
    public let changeLogSummary: String?

    public init(layers: [LRManifestLayer]) {
        self.layers = layers

        let optionRegistry = ActionKitSingleton.sharedActionKit().optionRegistry!

        errorSpecs = layers.map { layer in
            ArrayValue(layer.manifest["errors"]) { $0 as AnyObject } ?? []
        }.flatten()
        warningSpecs = layers.map { layer in
            ArrayValue(layer.manifest["warnings"]) { $0 as AnyObject } ?? []
        }.flatten()

        optionSpecs = layers.map { layer -> [OptionSpec] in
            let specs = JSONObjectsArrayValue(layer.manifest["options"]) ?? []
            let childSink = layer  // TODO: LRChildErrorSink(parentSink: layer, context: "rule TODO", uncleSink: self)
            return specs.mapIf { optionRegistry.parseOptionSpec($0, errorSink: childSink) }
        }.flatten()

        commandLineSpec = layers.mapIf { layer in
            ArrayValue(layer.manifest["cmdline"]) { $0 as? String }
        }.last

        changeLogSummary = layers.mapIf { layer in
            layer.manifest["changeLogSummary"] as? String
        }.last

        super.init(manifest: [:], errorSink: nil)
    }

    public func createOptions(rule rule: Rule) -> [Option] {
        return optionSpecs.map { $0.newOption(rule: rule) }
    }

}
