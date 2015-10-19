import Foundation
import ExpressiveCasting
import PackageManagerKit
import ATVersionKit
import ATPathSpec

public class Action : LRManifestBasedObject {

    public let container: ActionContainer

    public let identifier: String
    public let name: String
    public var kind: ActionKind
    
    public let ruleType: Rule.Type
    public let rowClassName: String

    private let fakeChangeExtension: String?

    public let combinedIntrinsicInputPathSpec: ATPathSpec

    public private(set) var packageConfigurations: [LRAssetPackageConfiguration]!

    public private(set) var manifestLayers: [LRManifestLayer]!

    public var primaryVersionSpace: LRVersionSpace?
    
    public let compilableFileTag: Tag?
    public let taggers: [Tagger]
    public private(set) var derivers: [Deriver]!

    public init(manifest: [String: AnyObject], container: ActionContainer) {
        self.container = container
        let identifier = manifest["id"]~~~ ?? ""
        self.identifier = identifier
        name = manifest["name"]~~~ ?? identifier
        // if (_identifier.length == 0)
        //     [self addErrorMessage:@"'id' attribute is required"];

        // if (_kind == ActionKindUnknown)
        //     [self addErrorMessage:[NSString stringWithFormat:@"'kind' attribute is required and must be one of %@", LRValidActionKindStrings()]];

        let type = manifest["type"]~~~ ?? ""
        switch type {
        case "filter":
            kind = .Filter
            ruleType = FilterRule.self
            rowClassName = "FilterRuleRow"
        case "compile-file":
            kind = .Compiler
            ruleType = CompileFileRule.self
            rowClassName = "CompileFileRuleRow"
        case "compile-folder":
            kind = .Postproc
            ruleType = CompileFolderRule.self
            rowClassName = "FilterRuleRow"
        case "run-tests":
            kind = .Postproc
            ruleType = RunTestsRule.self
            rowClassName = "FilterRuleRow"
        case "custom-command":
            kind = .Postproc
            ruleType = CustomCommandRule.self
            rowClassName = "CustomCommandRuleRow"
        case "user-script":
            kind = .Postproc
            ruleType = UserScriptRule.self
            rowClassName = "UserScriptRuleRow"
        default:
            fatalError("Missing or unknown action type")
        }

        if let inputPathSpecString: String = manifest["input"]~~~ {
            combinedIntrinsicInputPathSpec = ATPathSpec(string: inputPathSpecString, syntaxOptions:.FlavorExtended)
        } else {
            combinedIntrinsicInputPathSpec = ATPathSpec.emptyPathSpec()
        }

        if let outputSpecString: String = manifest["output"]~~~ {
            if (outputSpecString == "*.css") {
                fakeChangeExtension = "css"
            } else {
                fakeChangeExtension = nil
            }
        } else {
            fakeChangeExtension = nil
        }
        
        var taggers: [Tagger] = []
        if kind == .Compiler {
            compilableFileTag = Tag(name: "compilable.\(identifier)")
            taggers.append(FileSpecTagger(spec: combinedIntrinsicInputPathSpec, tag: compilableFileTag!))
        } else {
            compilableFileTag = nil
        }
        self.taggers = taggers

        super.init(manifest: manifest, errorSink: container)

        var derivers: [Deriver] = []
        if kind == .Compiler {
            derivers.append(CompileFileRuleDeriver(action: self))
        }
        self.derivers = derivers

        // Manifests
        let packageManager = ActionKitSingleton.sharedActionKit.packageManager
        let versionInfo = (manifest["versionInfo"] as? [String: AnyObject]) ?? [:]
        let versionInfoLayers = versionInfo.mapIf { (packageRefString, info) -> LRManifestLayer? in
            // no idea what this check means
            if packageRefString.hasPrefix("__") {
                return nil
            }
            let reference = packageManager.packageReferenceWithString(packageRefString)!
            return LRManifestLayer(manifest: info as! [String: AnyObject], requiredPackageReferences: [reference], errorSink: self)
        }

        let infoDictionaries = ArrayValue(manifest["info"]) { $0 as? [String: AnyObject] } ?? []
        manifestLayers = infoDictionaries.map { LRManifestLayer(manifest: $0, errorSink: self) } + versionInfoLayers

        let packageConfigurationManifests = ArrayValue(manifest["packages"]) { ArrayValue($0) { StringValue($0) } } ?? []
        packageConfigurations = packageConfigurationManifests.map { packagesManifest in
            return LRAssetPackageConfiguration(manifest: ["packages": packagesManifest], errorSink: self)
        }

        if packageConfigurations.isEmpty {
            primaryVersionSpace = nil
        } else {
            // wow, that's quite a chain
            primaryVersionSpace = packageConfigurations[0].packageReferences[0].type.versionSpace
        }
    }

    public override var description: String {
        return "\(kind) '\(identifier)'"
    }

    public func fakeChangeDestinationPathForSourceFile(file: ProjectFile) -> RelPath? {
        if let fakeChangeExtension = fakeChangeExtension {
            if file.path.hasPathExtension(fakeChangeExtension) {
                return nil
            } else {
                // TODO: use the matched input extension instead of the shortest extension
                let (path, found) = file.path.replaceShortestPathExtensionWith(fakeChangeExtension)
                if found {
                    return path
                } else {
                    return nil
                }
            }
        } else {
            return nil
        }
    }
    
    public func newRule(contextAction contextAction: LRContextAction, memento: JSONObject?) -> Rule {
        return ruleType.init(contextAction: contextAction, memento: memento)
    }

}
