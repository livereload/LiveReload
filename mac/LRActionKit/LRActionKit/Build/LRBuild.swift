import Foundation
import SwiftyFoundation
import ATPathSpec

public class LRBuild : NSObject {

    public let project: ProjectContext
    public let rules: [Rule]

    public private(set) var messages: [LRMessage] = []

    public private(set) var reloadRequests: [NSDictionary] = []
    private var _modifiedFiles = IndexedArray<String, ProjectFile>({ $0.relativePath })
    private var _compiledFiles = IndexedArray<String, ProjectFile>({ $0.relativePath })
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

    public init(project: ProjectContext, rules: [Rule]) {
        self.project = project
        self.rules = rules
    }

    public func addReloadRequest(reloadRequest: NSDictionary) {
        reloadRequests.append(reloadRequest)
    }

    public func addModifiedFiles(files: [ProjectFile]) {
        // dedup
        // TODO: add a duplicate target if the previous one has already been completed
        let newFiles = files.filter { !self._modifiedFiles.contains($0) }

        if newFiles.count > 0 {
            _modifiedFiles.extend(newFiles);

            for rule in rules {
                _pendingFileTargets.extend(rule.fileTargetsForModifiedFiles(newFiles))
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
        return reloadRequests.count > 0
    }

    private func _updateReloadRequests() {
        reloadRequests = []

        var filesToReload: [ProjectFile] = _modifiedFiles.list

        if let forcedStylesheetReloadSpec: ATPathSpec = project.forcedStylesheetReloadSpec {
            if forcedStylesheetReloadSpec.isNonEmpty() {
                let filesTriggeringForcedStylesheetReloading = filesToReload.filter { forcedStylesheetReloadSpec.matchesPath($0.relativePath, type: .File) }
                if filesTriggeringForcedStylesheetReloading.count > 0 {
                    addReloadRequest(["path": "force-reload-all-stylesheets.css", "originalPath": NSNull()])
                    removeElements(&filesToReload, filesTriggeringForcedStylesheetReloading)
                }
            }
        }

        for file in filesToReload {
            if _compiledFiles.contains(file) {
                continue  // compiled; wait for the destination file change event to send a reload request
            }

            let fullPath = file.absolutePath as String

            let actions = project.compilerActionsForFile(file)
            if let fakeDestinationName = findMapped(actions, { $0.fakeChangeDestinationNameForSourceFile(file) }) {
                let fakePath = fullPath.stringByDeletingLastPathComponent.stringByAppendingPathComponent(fakeDestinationName)
                addReloadRequest(["path": fakePath, "originalPath": fullPath, "localPath": NSNull()])
            } else {
                addReloadRequest(["path": fullPath, "originalPath": NSNull(), "localPath": fullPath])
            }
        }
    }

    public func sendReloadRequests() {
        _updateReloadRequests()

        if  reloadRequests.count > 0 {
            project.sendReloadRequest(changes: reloadRequests, forceFullReload: project.disableLiveRefresh)
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
            postNotification(LRBuildDidFinishNotification)
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

        if let target = popLast(&_pendingFileTargets) {
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

        return popFirst(&_pendingProjectTargets)
    }

    private func _buildProjectActions() {
        _pendingProjectTargets.extend(mapIf(rules) { $0.targetForModifiedFiles(self._modifiedFiles.list) })
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

        messages.extend(result.messages as [LRMessage])
        project.displayResult(result, key: key)
    }

}
