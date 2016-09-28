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
        
        let relPath = RelPath(path)

        for action in actionSet.contextActions {
            NSLog("%@", "Action \(action.action.identifier) has \(action.versions.count) versions:")
            for version in action.versions {
                NSLog("%@", "  - \(version.primaryVersion)")
            }
        }
        
        let suitableActions = actionSet.contextActions.filter { $0.action.combinedIntrinsicInputPathSpec.includes(relPath) && $0.action.ruleType == CompileFileRule.self }
        
        guard let action = suitableActions.first else {
            return false
        }
        
        // TODO: pick the right version!!!
        guard let version = action.versions.first else {
            return false
        }
        
        let rule = action.newInstance(memento: [:]) as! CompileFileRule
        rule.effectiveVersion = version
        
        let sourceFile = ProjectFile(path: relPath, project: self)
        guard let destinationFile = rule.destinationFileForSourceFile(sourceFile) else {
            return false
        }

        let result = LROperationResult()

        let step = ScriptInvocationStep(project: self)
        step.result = result

        rule.configureStep(step, forFile: sourceFile, destinationFile: destinationFile)
        
        step.completionHandler = { step in
            NSLog("DONE %@: %@ with result %@", rule.label, sourceFile.absolutePath, result)
        }
        
        NSLog("%@: %@", rule.label, sourceFile.absolutePath)
        step.invoke()
        
        return true

//        for (Compiler *compiler in [PluginManager sharedPluginManager].compilers) {
//            if (_compassDetected && [compiler.uniqueId isEqualToString:@"sass"])
//            continue;
//            else if (!_compassDetected && [compiler.uniqueId isEqualToString:@"compass"])
//            continue;
//            if ([compiler canCompileFileNamed:relativePath extension:extension]) {
//                compilerFound = YES;
//                CompilationOptions *compilationOptions = [self optionsForCompiler:compiler create:YES];
//                if (_compilationEnabled && compilationOptions.active) {
//                    [[NSNotificationCenter defaultCenter] postNotificationName:ProjectWillBeginCompilationNotification object:self];
//                    [self compile:relativePath under:_path with:compiler options:compilationOptions];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidEndCompilationNotification object:self];
//                    [Analytics trackCompilationWithCompilerNamed:compiler.uniqueId forProject:self];
//                    StatGroupIncrement(CompilerChangeCountStatGroup, compiler.uniqueId, 1);
//                    StatGroupIncrement(CompilerChangeCountEnabledStatGroup, compiler.uniqueId, 1);
//                    break;
//                } else {
//                    FileCompilationOptions *fileOptions = [self optionsForFileAtPath:relativePath in:compilationOptions];
//                    NSString *derivedName = fileOptions.destinationName;
//                    reload_session_add(_session, reload_request_create([derivedName UTF8String], [[_path stringByAppendingPathComponent:relativePath] UTF8String]));
//                    NSLog(@"Broadcasting a fake change in %@ instead of %@ (compiler %@).", derivedName, relativePath, compiler.name);
//                    StatGroupIncrement(CompilerChangeCountStatGroup, compiler.uniqueId, 1);
//                    break;
//                    //            } else if (compilationOptions.mode == CompilationModeDisabled) {
//                    //                compilerFound = NO;
//                }
//            }
//        }
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
