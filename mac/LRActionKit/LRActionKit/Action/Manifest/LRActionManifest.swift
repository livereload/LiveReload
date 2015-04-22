import Foundation
import SwiftyFoundation

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

        errorSpecs = flatten(layers.map { layer in
            ArrayValue(layer.manifest["errors"], { $0 as AnyObject }) ?? []
        })
        warningSpecs = flatten(layers.map { layer in
            ArrayValue(layer.manifest["warnings"], { $0 as AnyObject }) ?? []
        })

        optionSpecs = flatten(layers.map { layer -> [OptionSpec] in
            let specs = ArrayValue(layer.manifest["options"], { $0 as? [String: AnyObject] }) ?? []
            let childSink = layer  // TODO: LRChildErrorSink(parentSink: layer, context: "rule TODO", uncleSink: self)
            return mapIf(specs) { optionRegistry.parseOptionSpec($0, errorSink: childSink) }
        })

        commandLineSpec = lastOf(mapIf(layers) { layer in
            ArrayValue(layer.manifest["cmdline"], { $0 as? String })
        })

        changeLogSummary = lastOf(mapIf(layers) { layer in
            layer.manifest["changeLogSummary"] as? String
        })

        super.init(manifest: nil, errorSink: nil)
    }

    public func createOptions(#rule: Rule) -> [Option] {
        return optionSpecs.map { $0.newOption(rule: rule) }
    }

}
