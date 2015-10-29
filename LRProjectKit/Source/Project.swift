import Foundation
import ExpressiveFoundation
import ATPathSpec
import PackageManagerKit
import LRActionKit

public class Project: EmitterType, ProjectContext {

    public var _listeners = EventListenerStorage()

    public let rootURL: NSURL

    public var actionSet: ActionSet!

    public var resolutionContext: LRPackageResolutionContext

    public init(rootURL: NSURL) {
        self.rootURL = rootURL
        resolutionContext = LRPackageResolutionContext()

        actionSet = ActionSet(project: self)
    }

    public func dispose() {
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

}
