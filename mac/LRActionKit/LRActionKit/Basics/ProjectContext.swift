import Foundation
import ATPathSpec

@objc public protocol ProjectContext : NSObjectProtocol {

    var rootURL: NSURL { get }
    var path: String { get }

    var forcedStylesheetReloadSpec: ATPathSpec? { get }

    var disableLiveRefresh: Bool { get }

    func hackhack_didWriteCompiledFile(file: ProjectFile)
    func hackhack_didFilterFile(file: ProjectFile)
    func hackhack_shouldFilterFile(file: ProjectFile) -> Bool

    func displayResult(result: LROperationResult, key: String)

    func compilerActionsForFile(file: ProjectFile) -> [Action]

    func sendReloadRequest(#changes: [NSDictionary], forceFullReload: Bool)
        //    Glue().postMessage(["service": "reloader", "command": "reload", "changes": reloadRequests as NSArray, "forceFullReload": project.disableLiveRefresh as Bool])
        //    postNotification(ProjectDidDetectChangeNotification)
        //    StatIncrement(BrowserRefreshCountStat, 1)

}
