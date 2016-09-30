import Foundation
import LRProjectKit
import LRActionKit
import PackageManagerKit
import ATPathSpec
import ExpressiveFoundation

@objc
public class NewProject: NSObject {

    public let rootURL: NSURL
    
    public private(set) var actionSet: ActionSet!
    
    public let resolutionContext: LRPackageResolutionContext
    
    private var o = Observation()

    private unowned var oldProject: OldProject
    
    public init(rootURL: NSURL, oldProject: OldProject) {
        self.rootURL = rootURL
        self.oldProject = oldProject
        resolutionContext = LRPackageResolutionContext()
        super.init()
        
        actionSet = ActionSet(project: self)
        
        o += workspace.plugins.updating.subscribe(self, NewProject.onPluginsProcessingBatchDidFinish)
        updateActions()
    }
    
    private func onPluginsProcessingBatchDidFinish(event: ProcessableBatchDidFinish) {
        updateActions()
    }
    
    private func updateActions() {
        let actions = workspace.plugins.plugins.flatMap { $0.actions }
        actionSet.replaceActions(actions)
    }
    
    public func compileFile(at path: String) -> Bool {
        // TODO: Compass
        
        let sourceRelPath = RelPath(path)
        let sourceFile = ProjectFile(path: sourceRelPath, project: self)
        
        if !sourceFile.exists {
            return true
        }

        for action in actionSet.contextActions {
            NSLog("%@", "Action \(action.action.identifier) has \(action.versions.count) versions:")
            for version in action.versions {
                NSLog("%@", "  - \(version.primaryVersion)")
            }
        }
        
        let suitableActions = actionSet.contextActions.filter { $0.action.combinedIntrinsicInputPathSpec.includes(sourceRelPath) && $0.action.ruleType == CompileFileRule.self }

        guard let action = suitableActions.first else {
            return false
        }
        
        if !oldProject.compilationEnabled {
            if let destinationRelPath = action.action.fakeChangeDestinationPathForSourceFile(sourceFile) {
//            FileCompilationOptions *fileOptions = [self optionsForFileAtPath:relativePath in:compilationOptions];
//            NSString *derivedName = fileOptions.destinationName;
                oldProject.addFakeChangeForPath(destinationRelPath.pathString, originalPath: sourceFile.path.pathString)
                StatGroupIncrement(CompilerChangeCountStatGroup, action.action.identifier, 1)
            }
            return true
        }
        
        // TODO: pick the right version!!!
        guard let version = action.versions.first else {
            return false
        }
        
        let rule = action.newInstance(memento: [:]) as! CompileFileRule
        rule.effectiveVersion = version
        
        guard let destinationFile = rule.destinationFileForSourceFile(sourceFile) else {
            return false
        }

        let result = LROperationResult()

        let step = ScriptInvocationStep(project: self)
        step.result = result

        rule.configureStep(step, forFile: sourceFile, destinationFile: destinationFile)
        
        step.completionHandler = { step in
            NSLog("DONE %@: %@ with result %@", rule.label, sourceFile.absolutePath, result.messages)
            NSNotificationCenter.defaultCenter().postNotificationName(ProjectDidEndCompilationNotification, object: self.oldProject)
            Analytics.trackCompilationWithCompilerNamed(action.action.identifier, forProjectPath: self.rootURL.path)
            StatGroupIncrement(CompilerChangeCountStatGroup, action.action.identifier, 1)
            StatGroupIncrement(CompilerChangeCountEnabledStatGroup, action.action.identifier, 1)
            
            self.displayMessages(result.messages)
        }
        
        NSLog("%@: %@", rule.label, sourceFile.absolutePath)
        
        NSNotificationCenter.defaultCenter().postNotificationName(ProjectWillBeginCompilationNotification, object: oldProject)
        step.invoke()
        
        return true
    }
    
    private func displayMessages(messages: [LRMessage]) {
        let key = rootURL.path!
        if let message = messages.first {
            let output = ToolOutput(message: message)
            ToolOutputWindowController(compilerOutput: output, key: key).show()
        } else {
            ToolOutputWindowController.hideOutputWindowWithKey(key)
        }
    }
    
    public func dispose() {
    }

    private let _processing = ProcessingGroup()
    
    public var _listeners = EventListenerStorage()
    
}

extension NewProject: ProjectContext {

    public var displayName: String {
        return rootURL.lastPathComponent!
    }
    
    public var forcedStylesheetReloadSpec: ATPathSpec? {
        return nil
    }
    
    public var rubyInstanceForBuilding: RuntimeInstance {
        return workspace.rubies.instanceIdentifiedBy("system")
    }
    
    public var disableLiveRefresh: Bool {
        return false
    }
    
    public func hackhack_didWriteCompiledFile(file: ProjectFile) {
    }
    public func hackhack_didFilterFile(file: ProjectFile) {
    }
    public func hackhack_shouldFilterFile(file: ProjectFile) -> Bool {
        return true
    }
    
    public func displayResult(result: LROperationResult, key: String) {
    }
    
    public func compilerActionsForFile(file: ProjectFile) -> [Action] {
        return []
    }
    
    public func sendReloadRequest(changes changes: [NSDictionary], forceFullReload: Bool) {
    }
    
    public func rootFilesForFiles(files: [ProjectFile]) -> [ProjectFile] {
        return files
    }
    
    public func setAnalysisInProgress(inProgress: Bool, forTask task: NSObject) {
    }
    
    public var processing: Processable {
        return _processing
    }
    
}

private extension ToolOutput {
    
    convenience init(message: LRMessage) {
        let m = message.message

        let type: ToolOutputType
        switch m.severity {
        case .Error:
            type = .Error
        case .Warning:
            type = .Error
        case .Raw:
            type = .ErrorRaw
        }
        
        self.init(compiler: nil, type: type, sourcePath: m.file, line: (m.line ?? 0), message: (m.text ?? ""), output: (m.text ?? ""))
    }
    
}


//
//extension Project: ProjectContext {
//    
//    var rootURL: NSURL { get }
//    
//    var forcedStylesheetReloadSpec: ATPathSpec? { get }
//    
//    var disableLiveRefresh: Bool { get }
//    
//    func hackhack_didWriteCompiledFile(file: ProjectFile)
//    func hackhack_didFilterFile(file: ProjectFile)
//    func hackhack_shouldFilterFile(file: ProjectFile) -> Bool
//    
//    func compilerActionsForFile(file: ProjectFile) -> [Action]
//    
//    func sendReloadRequest(changes changes: [NSDictionary], forceFullReload: Bool)
//    
//    func rootFilesForFiles(files: [ProjectFile]) -> [ProjectFile]
//    
//    func setAnalysisInProgress(inProgress: Bool, forTask task: NSObject)
//    
//    var resolutionContext: LRPackageResolutionContext { get }
//    
//    var rubyInstanceForBuilding: RuntimeInstance { get }
//    
//}
