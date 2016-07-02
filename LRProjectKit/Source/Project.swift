import Foundation
import ExpressiveFoundation
import ATPathSpec
import PackageManagerKit
import LRActionKit
import Uniflow

public class Project: StdEmitterType, ProjectContext, Identifiable {

    public let uuid = NSUUID().UUIDString

    public let rootURL: NSURL

    public var actionSet: ActionSet!

    public var resolutionContext: LRPackageResolutionContext

    public init(rootURL: NSURL) {
        self.rootURL = rootURL
        resolutionContext = LRPackageResolutionContext()

        actionSet = ActionSet(project: self)
    }

    public var uniqueIdentifier: String {
        return uuid
    }

    public func dispose() {
    }

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

    private let _processing = ProcessingGroup()

    public var _listeners = EventListenerStorage()

}
