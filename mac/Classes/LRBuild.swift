import Foundation
import LRActionKit

class LRBuild : NSObject {

    let project: Project
    let rules: [Rule]

    var messages: [LRMessage] = []

    var reloadRequests: [NSDictionary] { return _reloadRequests }
    var _reloadRequests: [NSDictionary] = []
    var _modifiedFiles = IndexedArray<String, ProjectFile>({ $0.relativePath })
    var _compiledFiles = IndexedArray<String, ProjectFile>({ $0.relativePath })
    var _pendingFileTargets: [LRTarget] = []
    var _pendingProjectTargets: [LRTarget] = []

    var _runningTarget: LRTarget?
    var _waitingForMoreChangesBeforeFinishing = false

    let _gracePeriodWithoutReloadRequests = 0.25
    let _gracePeriodWithReloadRequests = 0.05

    // XXX: a temporary hack
    var _executingProjectActions = false

    var started: Bool { return _started }
    var _started: Bool = false

    var finished: Bool { return _finished }
    var _finished: Bool = false

    var firstFailure: LROperationResult? { return _firstFailure }
    var _firstFailure: LROperationResult?

    init(project: Project, rules: [Rule]) {
        self.project = project
        self.rules = rules
    }

    func addReloadRequest(reloadRequest: NSDictionary) {
        _reloadRequests.append(reloadRequest)
    }

    func addModifiedFiles(files: [ProjectFile]) {
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

    func markAsConsumedByCompiler(file: ProjectFile) {
        _compiledFiles.append(file)
    }


    // MARK: Reload requess

    var _hasReloadRequests: Bool {
        return _reloadRequests.count > 0
    }

    func _updateReloadRequests() {
        _reloadRequests = []

        var filesToReload: [ProjectFile] = _modifiedFiles.list

        if let forcedStylesheetReloadSpec: ATPathSpec = project.forcedStylesheetReloadSpec {
            if forcedStylesheetReloadSpec.isNonEmpty() {
                let filesTriggeringForcedStylesheetReloading = filesToReload.filter { forcedStylesheetReloadSpec.matchesPath($0.relativePath, type: .File) }
                if filesTriggeringForcedStylesheetReloading.count > 0 {
                    addReloadRequest(["path": "force-reload-all-stylesheets.css", "originalPath": NSNull()])
                    removeIntersection(&filesToReload, filesTriggeringForcedStylesheetReloading)
                }
            }
        }

        for file in filesToReload {
            if _compiledFiles.contains(file) {
                continue  // compiled; wait for the destination file change event to send a reload request
            }

            let fullPath = file.absolutePath as String

            let actions = project.compilerActionsForFile(file) as [Action]
            if let fakeDestinationName = actions.findMapIf({ $0.fakeChangeDestinationNameForSourceFile(file) }) {
                let fakePath = fullPath.stringByDeletingLastPathComponent.stringByAppendingPathComponent(fakeDestinationName)
                addReloadRequest(["path": fakePath, "originalPath": fullPath, "localPath": NSNull()])
            } else {
                addReloadRequest(["path": fullPath, "originalPath": NSNull(), "localPath": fullPath])
            }
        }
    }

    func sendReloadRequests() {
        _updateReloadRequests()

        if  _reloadRequests.count > 0 {
            Glue().postMessage(["service": "reloader", "command": "reload", "changes": _reloadRequests as NSArray, "forceFullReload": project.disableLiveRefresh as Bool])
            postNotification(ProjectDidDetectChangeNotification)
            StatIncrement(BrowserRefreshCountStat, 1)
        }
    }


    // MARK: Lifecycle

    func start() {
        if !_started {
            _started = true
            _executeNextTarget()
        }
    }

    func _finish() {
        if (!_finished) {
            _finished = true
            postNotification(LRBuildDidFinishNotification)
        }
    }


    // MARK: Execution

    let _delayed_executeNextTarget = Delayed()
    func _executeNextTarget() {
        if _runningTarget {
            return
        }

        if _waitingForMoreChangesBeforeFinishing {
            _delayed_executeNextTarget.cancel()
            _waitingForMoreChangesBeforeFinishing = false
        }

        if let target = _pendingFileTargets.removeLastOrNil() {
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

    func _obtainNextProjectTarget() -> LRTarget? {
        // XXX: a temporary hack, need a better time to populate project rules
        if !_executingProjectActions {
            _executingProjectActions = true
            _buildProjectActions()
        }
        // end hack

        return _pendingProjectTargets.removeFirstOrNil()
    }

    func _buildProjectActions() {
        _pendingProjectTargets.extend(rules.mapIf { $0.targetForModifiedFiles(self._modifiedFiles.list) })
    }

    func _executeTarget(target: LRTarget) {
        _runningTarget = target
        target.invoke(build: self) {
            dispatch_async(dispatch_get_main_queue()) {
                self._runningTarget = nil
                self._executeNextTarget()
            }
        }
    }


    // MARK: Results

    var failed: Bool {
        return _firstFailure != nil
    }

    func addOperationResult(result: LROperationResult, forTarget target: LRTarget, key: String) {
        if !_firstFailure && result.failed {
            _firstFailure = result
        }

        messages.extend(result.messages as [LRMessage])
        project.displayResult(result, key: key)
    }

}
