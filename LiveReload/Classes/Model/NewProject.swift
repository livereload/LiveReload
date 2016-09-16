import Foundation
import LRProjectKit
import LRActionKit
import PackageManagerKit
import ATPathSpec
import ExpressiveFoundation

public class NewProject: NSObject {

    public let rootURL: NSURL
    
    public private(set) var actionSet: ActionSet!
    
    public let resolutionContext: LRPackageResolutionContext
    
    public init(rootURL: NSURL) {
        self.rootURL = rootURL
        resolutionContext = LRPackageResolutionContext()
        super.init()
        
        actionSet = ActionSet(project: self)
    }
    
    public func compileFile(at path: String) -> Bool {
//        for action in actionSet.contextActions {
//        }

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
        return false
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
        return RubyInstance(memento: nil, additionalInfo: nil)
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
