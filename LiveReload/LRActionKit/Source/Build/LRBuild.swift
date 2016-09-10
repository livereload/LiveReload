import Foundation
import ExpressiveCollections
import ExpressiveFoundation
import ExpressiveCasting
import ATPathSpec

public class LRBuild : NSObject, StdEmitterType {

    public struct DidProduceResult: EventType {
        public let result: LROperationResult
        public let target: LRTarget
        public let key: String
    }

    public struct DidProduceReloadRequest: EventType {
        public let request: BrowserReloadRequest
    }

    public struct DidFinish: EventType {
    }

    public let rules: [Rule]
    public let actions: [Action]
    public let configuration: BuildConfigurationProtocol

    public private(set) var messages: [LRMessage] = []

    public private(set) var browserChanges: [BrowserChange] = []
    private var _modifiedFiles = IndexedArray<String, ProjectFile>() { $0.relativePath }
    private var _compiledFiles = IndexedArray<String, ProjectFile>() { $0.relativePath }
    private var _pendingFileTargets: [LRTarget] = []
    private var _pendingProjectTargets: [LRTarget] = []

    private var _runningTarget: LRTarget?
    private var _waitingForMoreChangesBeforeFinishing = false

    private let _gracePeriodWithoutReloadRequests = 0.25
    private let _gracePeriodWithReloadRequests = 0.05

    // XXX: a temporary hack
    private var _executingProjectActions = false

    public private(set) var started: Bool = false

    public private(set) var finished: Bool = false

    public private(set) var firstFailure: LROperationResult?

    public init(rules: [Rule], actions: [Action], configuration: BuildConfigurationProtocol) {
        self.rules = rules
        self.actions = actions
        self.configuration = configuration
    }

    public func addReloadRequest(reloadRequest: BrowserChange) {
        browserChanges.append(reloadRequest)
    }

    public func addModifiedFiles(files: [ProjectFile]) {
        // dedup
        // TODO: add a duplicate target if the previous one has already been completed
        let newFiles = files.filter { !self._modifiedFiles.contains($0) }

        if newFiles.count > 0 {
            _modifiedFiles.extend(newFiles);

            for rule in rules {
                _pendingFileTargets.appendContentsOf(rule.fileTargetsForModifiedFiles(newFiles))
            }

            if (_waitingForMoreChangesBeforeFinishing) {
                _executeNextTarget()
            }
        }
    }


    // MARK: Compilers

    public func markAsConsumedByCompiler(file: ProjectFile) {
        _compiledFiles.append(file)
    }


    // MARK: Reload requess

    private var _hasReloadRequests: Bool {
        return browserChanges.count > 0
    }

    private func _updateReloadRequests() {
        browserChanges = []

        var filesToReload: [ProjectFile] = _modifiedFiles.list

        if let forcedStylesheetReloadSpec: ATPathSpec = configuration.forcedStylesheetReloadSpec {
            if forcedStylesheetReloadSpec.isNonEmpty() {
                let filesTriggeringForcedStylesheetReloading = filesToReload.filter { forcedStylesheetReloadSpec.matchesPath($0.relativePath, type: .File) }
                if filesTriggeringForcedStylesheetReloading.count > 0 {
                    addReloadRequest(BrowserChange(path: "force-reload-all-stylesheets.css", localPath: nil, originalPath: nil))
                    filesToReload.removeElements(filesTriggeringForcedStylesheetReloading)
                }
            }
        }

        for file in filesToReload {
            if _compiledFiles.contains(file) {
                continue  // compiled; wait for the destination file change event to send a reload request
            }

            let fakeDestinationPath = actions.findMapped { $0.fakeChangeDestinationPathForSourceFile(file) }
            if let fakeDestinationPath = fakeDestinationPath {
                let fakeURL = fakeDestinationPath.resolve(baseURL: file.project.rootURL)
                addReloadRequest(BrowserChange(path: fakeURL.path!, localPath: nil, originalPath: file.absolutePath))
            } else {
                addReloadRequest(BrowserChange(path: file.absolutePath, localPath: file.absolutePath, originalPath: nil))
            }
        }
    }

    public func sendReloadRequests() {
        _updateReloadRequests()

        if browserChanges.count > 0 {
            emit(DidProduceReloadRequest(request: BrowserReloadRequest(changes: browserChanges, forceFullReload: configuration.disableLiveRefresh)))
        }
    }


    // MARK: Lifecycle

    public func start() {
        if !started {
            started = true
            _executeNextTarget()
        }
    }

    private func _finish() {
        if (!finished) {
            finished = true
            emit(DidFinish())
        }
    }


    // MARK: Execution

    private let _delayed_executeNextTarget = Delayed()
    private func _executeNextTarget() {
        if _runningTarget != nil {
            return
        }

        if _waitingForMoreChangesBeforeFinishing {
            _delayed_executeNextTarget.cancel()
            _waitingForMoreChangesBeforeFinishing = false
        }

        if let target = _pendingFileTargets.popLast() {
            _executeTarget(target)
        } else if let target = _obtainNextProjectTarget() {
            _executeTarget(target)
        } else {
            _updateReloadRequests()
            let gracePeriod = _hasReloadRequests ? _gracePeriodWithReloadRequests : _gracePeriodWithoutReloadRequests

            _waitingForMoreChangesBeforeFinishing = true
            _delayed_executeNextTarget.performAfterDelay(gracePeriod) {
                self._waitingForMoreChangesBeforeFinishing = false
                self._finish()
            }
        }
    }

    private func _obtainNextProjectTarget() -> LRTarget? {
        // XXX: a temporary hack, need a better time to populate project rules
        if !_executingProjectActions {
            _executingProjectActions = true
            _buildProjectActions()
        }
        // end hack

        return _pendingProjectTargets.popFirst()
    }

    private func _buildProjectActions() {
        _pendingProjectTargets.appendContentsOf(rules.mapIf { $0.targetForModifiedFiles(self._modifiedFiles.list) })
    }

    private func _executeTarget(target: LRTarget) {
        _runningTarget = target
        target.invoke(build: self) {
            dispatch_async(dispatch_get_main_queue()) {
                self._runningTarget = nil
                self._executeNextTarget()
            }
        }
    }


    // MARK: Results

    public var failed: Bool {
        return firstFailure != nil
    }

    public func addOperationResult(result: LROperationResult, forTarget target: LRTarget, key: String) {
        if firstFailure == nil && result.failed {
            firstFailure = result
        }

        messages.appendContentsOf(result.messages)
        emit(DidProduceResult(result: result, target: target, key: key))
    }

    public var _listeners = EventListenerStorage()

}
