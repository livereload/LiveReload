import Foundation
import ExpressiveFoundation
import ExpressiveCasting
import ExpressiveCocoa
import ExpressiveCollections
import ATVersionKit
import ATPathSpec
import PackageManagerKit

public class Rule : NSObject {
    private var o = Observation()

    public let contextAction: LRContextAction

    public var kind: ActionKind {
        return contextAction.action.kind
    }

    public var action: Action {
        return contextAction.action
    }

    public var label: String {
        return action.name
    }

    public var project: ProjectContext {
        return contextAction.project
    }

    public var enabled: Bool = true {
        didSet {
            didChange()
        }
    }

    public var nonEmpty: Bool {
        return true
    }

    public var inputFilterOption: FilterOption = FilterOption(directory: RelPath()) {
        didSet {
            if (inputFilterOption != oldValue) {
                updateInputPathSpec()
                didChange()
            }
        }
    }

    public var intrinsicInputPathSpec: ATPathSpec? {
        didSet {
            updateInputPathSpec()
        }
    }

    public required init(contextAction: LRContextAction, memento: JSONObject?) {
        self.contextAction = contextAction
        self.primaryVersionSpec = LRVersionSpec.stableVersionSpecMatchingAnyVersionInVersionSpace(contextAction.action.primaryVersionSpace)
        super.init()
        self.memento = [:]
        if let m = memento {
            for (k, v) in m {
                self.memento.updateValue(v, forKey: k)
            }
        }

        do {
            try loadFromMemento()
        } catch let e as NSError {
            print("*** Error loading memento: \(e) *** memento = \(memento)")
        }
        updateInputPathSpec()
        _initEffectiveVersion()
    }

    override public var description: String {
        get {
            return "<\(contextAction)> v=\(primaryVersionSpec) src=\(inputFilterOption)"
        }
    }

    public func obtainUpdatedMemento() -> JSONObject {
        updateMemento()
        return memento
    }

    public func setMemento(newValue: JSONObject) throws {
        memento = newValue
        try loadFromMemento()
    }

    public private(set) var inputPathSpec: ATPathSpec = ATPathSpec.emptyPathSpec()

    internal var memento: Dictionary<String, AnyObject> = [:]
    private var _options: Dictionary<String, AnyObject> = [:]

    public /*protected*/ func loadFromMemento() throws {
        enabled = memento["enabled"]~~~ ?? true
        inputFilterOption = try FilterOption(memento: memento["filter"]~~~ ?? "subdir:.")
        if let ver: String = memento["version"]~~~ {
            primaryVersionSpec = LRVersionSpec(string: ver, inVersionSpace: action.primaryVersionSpace)
        } else {
            primaryVersionSpec = LRVersionSpec.stableVersionSpecMatchingAnyVersionInVersionSpace(action.primaryVersionSpace)
        }

        if let opts: AnyObject? = memento["options"] {
            _options = (opts as? [String: AnyObject]) ?? [:]
        } else {
            _options = [:]
        }
    }

    public /*protected*/ func updateMemento() {
        memento["action"] = action.identifier
        memento["enabled"] = enabled
        memento["filter"] = inputFilterOption.memento
        memento["version"] = primaryVersionSpec.stringValue
        if _options.count > 0 {
            memento["options"] = _options
        } else {
            memento["options"] = nil
        }
    }

    private func updateInputPathSpec() {
        var spec = inputFilterOption.pathSpec
        if intrinsicInputPathSpec != nil {
            spec = ATPathSpec(matchingIntersectionOf: [spec, intrinsicInputPathSpec!])
        }
        inputPathSpec = spec
    }

    // MARK: Target selection

    public var supportsFileTargets: Bool {
        return false
    }

    public func targetForModifiedFiles(files: [ProjectFile]) -> LRTarget? {
        return nil
    }

    public func fileTargetForRootFile(file: ProjectFile) -> LRTarget? {
        return nil
    }

    public func fileTargetsForModifiedFiles(modifiedFiles: [ProjectFile]) -> [LRTarget] {
        if !supportsFileTargets {
            return []
        }
        let matchingFiles = modifiedFiles.filter(inputPathSpecMatchesFile)
        let rootFiles = project.rootFilesForFiles(matchingFiles) as [ProjectFile]
        let matchingRootFiles = rootFiles.filter(inputPathSpecMatchesFile)
        return matchingRootFiles.mapIf { self.fileTargetForRootFile($0) }
    }

    public func inputPathSpecMatchesFiles(files: [ProjectFile]) -> Bool {
        return files.contains(inputPathSpecMatchesFile)
    }

    public func inputPathSpecMatchesFile(file: ProjectFile) -> Bool {
        return self.inputPathSpec.matchesPath(file.relativePath, type: ATPathSpecEntryType.File)
    }


    // MARK: Compilation

    public func compileFile(file: ProjectFile, result: LROperationResult, completionHandler: dispatch_block_t) {
    }

    public func handleDeletionOfFile(file: ProjectFile) {
    }

    public func invokeWithModifiedFiles(files: [ProjectFile], result: LROperationResult, completionHandler: dispatch_block_t) {
    }


    // MARK: Custom arguments

    public var customArguments: [String] {
        get {
            return _options["custom-args"]~~~ ?? []
        }
        set {
            setOptionValue((newValue.count > 0 ? newValue : nil), forKey: "custom-args")
        }
    }

    public var customArgumentsString: String {
        get {
            return (customArguments as NSArray).p2_quotedArgumentStringUsingBourneQuotingStyle()
        }
        set {
            customArguments = (newValue as NSString).p2_argumentsArrayUsingBourneQuotingStyle()
        }
    }


    // MARK: Options

    public func optionValueForKey(key: String) -> AnyObject? {
        return _options[key]
    }

    public func setOptionValue(value: AnyObject?, forKey key: String) {
        if _options[key] !== value {
            _options[key] = value
            didChange()
        }
    }


    // MARK: LROption objects

    public func createOptions() -> [Option] {
        var options: [Option] = []
        options <<< VersionOption(rule: self)
        if let ev = effectiveVersion {
            options += ev.manifest.createOptions(rule: self)
        }
        options <<< CustomArgumentsOption(rule: self)
        return options
    }


    // MARK: Versions

    public var primaryVersionSpec: LRVersionSpec {
        didSet {
            if (primaryVersionSpec != oldValue) {
                didChange()
                _updateEffectiveVersion()
            }
        }
    }

    public var effectiveVersion: LRActionVersion?

    private func _computeEffectiveVersion() -> LRActionVersion? {
        return contextAction.versions.reverse().find { self.primaryVersionSpec.matchesVersion($0.primaryVersion, withTag: LRVersionTag.Unknown) }
    }

    private var _c_updateEffectiveVersion = Coalescence()
    private func _updateEffectiveVersion() {
        _c_updateEffectiveVersion.perform {
            self.effectiveVersion = self._computeEffectiveVersion()
            print("\(self) effectiveVersion = \(self.effectiveVersion)")
            self.postNotification(LRRuleEffectiveVersionDidChangeNotification)
        }
    }

    private func _initEffectiveVersion() {
        _c_updateEffectiveVersion.monitorBlock = weakify(self, Rule._updateEffectiveVersionState)

        o.on(LRContextAction.didChangeVersionsNotification, self, Rule._updateEffectiveVersion)
        _updateEffectiveVersion()
    }

    private func _updateEffectiveVersionState(running: Bool) {
        project.setAnalysisInProgress(running, forTask: self)
    }

    public var missingEffectiveVersionError: NSError {
        let available = contextAction.versions.map { $0.primaryVersion.description }.joinWithSeparator(", ")
        return NSError(ActionKitErrorDomain as String, ActionKitErrorCode.NoMatchingVersion.rawValue, "No available version matched for version spec \(primaryVersionSpec), available versions: \(available)")
    }


    // MARK: Change notification

    public /*protected*/ func didChange() {
        postNotification("SomethingChanged")
    }


    // MARK: Build

    public func configureStep(step: ScriptInvocationStep) {
        print("configureStep: project.path = \(project.path)")
        step.addStringValue("project_dir", project.path)

        if let eff = effectiveVersion {
            let manifest = eff.manifest
            step.commandLine = manifest.commandLineSpec ?? []
            for (key, value) in action.container.substitutionValues {
                step.addStringValue(key, value)
            }

            for package in eff.packageSet.packages as! [LRPackage] {
                step.addStringValue(package.identifier, package.sourceFolderURL.path!)
                step.addStringValue("\(package.identifier).ver", package.version.description)
            }
        }

        var additionalArguments: [String] = []
        let opt = self.createOptions()
        for option in opt {
            additionalArguments.appendContentsOf(option.commandLineArguments as [String])
        }
        additionalArguments.appendContentsOf(customArguments)

        step.addStringMultiValue("additional", additionalArguments)
    }

    public func configureResult(result: LROperationResult) {
        if let eff = effectiveVersion {
            result.errorSyntaxManifest = ["errors": eff.manifest.errorSpecs, "warnings": eff.manifest.warningSpecs]
        }
    }

}
