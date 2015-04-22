import Foundation
import SwiftyFoundation
import PiiVersionKit
import ATPathSpec
import LRCommons
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

    public var inputFilterOption: FilterOption = FilterOption(subfolder: "") {
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

    public required init(contextAction: LRContextAction, memento: NSDictionary?) {
        self.contextAction = contextAction
        self.primaryVersionSpec = LRVersionSpec.stableVersionSpecMatchingAnyVersionInVersionSpace(contextAction.action.primaryVersionSpace)
        super.init()
        self.memento = [:]
        if let m = memento as? [String: AnyObject] {
            for (k, v) in m {
                self.memento.updateValue(v, forKey: k)
            }
        }

        loadFromMemento()
        updateInputPathSpec()
        _initEffectiveVersion()
    }

    override public var description: String {
        get {
            return "<\(contextAction)> v=\(primaryVersionSpec) src=\(inputFilterOption)"
        }
    }

    public var theMemento: Dictionary<String, AnyObject> {
        get {
            updateMemento()
            return memento
        }
        set {
            memento = newValue
            loadFromMemento()
        }
    }

    public private(set) var inputPathSpec: ATPathSpec = ATPathSpec.emptyPathSpec()

    internal var memento: Dictionary<String, AnyObject> = [:]
    private var _options: Dictionary<String, AnyObject> = [:]

    public /*protected*/ func loadFromMemento() {
        enabled = memento["enabled"] ~|||~ true
        inputFilterOption = FilterOption(memento: memento["filter"] ~|||~ "subdir:.")
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
        if spec != nil {
            if intrinsicInputPathSpec != nil {
                spec = ATPathSpec(matchingIntersectionOf: [spec!, intrinsicInputPathSpec!])
            }
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
        return mapIf(matchingRootFiles) { self.fileTargetForRootFile($0) }
    }

    public func inputPathSpecMatchesFiles(files: [ProjectFile]) -> Bool {
        return contains(files, inputPathSpecMatchesFile)
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
            return _options["custom-args"] ~|||~ []
        }
        set {
            setOptionValue((newValue.count > 0 ? newValue : nil), forKey: "custom-args")
        }
    }

    public var customArgumentsString: String {
        get {
            return quotedArgumentStringUsingBourneQuotingStyle(customArguments)
        }
        set {
            customArguments = newValue.argumentsArrayUsingBourneQuotingStyle()
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
        return findIf(reverse(contextAction.versions)) { self.primaryVersionSpec.matchesVersion($0.primaryVersion, withTag: LRVersionTag.Unknown) }
    }

    private var _c_updateEffectiveVersion = Coalescence()
    private func _updateEffectiveVersion() {
        _c_updateEffectiveVersion.perform {
            self.effectiveVersion = self._computeEffectiveVersion()
            println("\(self) effectiveVersion = \(self.effectiveVersion)")
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
        var available = join(", ", contextAction.versions.map { $0.primaryVersion.description })
        return NSError(ActionKitErrorDomain as String, ActionKitErrorCode.NoMatchingVersion.rawValue, "No available version matched for version spec \(primaryVersionSpec), available versions: \(available)")
    }


    // MARK: Change notification

    public /*protected*/ func didChange() {
        postNotification("SomethingChanged")
    }


    // MARK: Build

    public func configureStep(step: ScriptInvocationStep) {
        step.project = project
        println("configureStep: project.path = \(project.path)")
        let s: NSObject? = project.path
        step.addValue(s, forSubstitutionKey: "project_dir")

        if let eff = effectiveVersion {
            let manifest = eff.manifest
            step.commandLine = manifest.commandLineSpec
            for (key, value) in action.container.substitutionValues {
                step.addValue(value, forSubstitutionKey: key)
            }

            for package in eff.packageSet.packages as! [LRPackage] {
                step.addValue(package.sourceFolderURL.path! as String, forSubstitutionKey: package.identifier)
                step.addValue(package.version.description as String, forSubstitutionKey: "\(package.identifier).ver")
            }
        }

        var additionalArguments: [String] = []
        let opt = self.createOptions()
        for option in opt {
            additionalArguments.extend(option.commandLineArguments as [String])
        }
        additionalArguments.extend(customArguments)

        step.addValue(additionalArguments as NSArray, forSubstitutionKey: "additional")
    }

    public func configureResult(result: LROperationResult) {
        if let eff = effectiveVersion {
            result.errorSyntaxManifest = ["errors": eff.manifest.errorSpecs, "warnings": eff.manifest.warningSpecs]
        }
    }

}
