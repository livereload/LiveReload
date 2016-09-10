import ExpressiveFoundation
import Cocoa
import LRProjectKit
import ATPathSpec
import XCTest

enum ProjectSource {

    case Local
    case Integration

}

class ProjectTestCase: XCTestCase {

    var project: Project!

    override func tearDown() {
        project?.dispose()
        super.tearDown()
    }

    func setupPlugins() {

    }

    func runSelfTest(source: ProjectSource, _ name: String) {
        setupTestProject(source, name)
    }

    func setupTestProject(source: ProjectSource, _ name: String) {
        var containerDirectoryURL: NSURL
        switch source {
        case .Local:
            containerDirectoryURL = fixturesDirectoryURL.URLByAppendingPathComponent("Projects", isDirectory: true)
        case .Integration:
            containerDirectoryURL = testProjectsDirectoryURL
        }
        let projectURL = containerDirectoryURL.URLByAppendingPathComponent(name, isDirectory: true)

        project = Project(rootURL: projectURL)
        waitForProject()
    }

    func waitForProject(timeout timeout: NSTimeInterval = 1) {
        waitForProcessable(project.processing, timeout: timeout)

    }

    func waitForProcessable(processable: Processable, timeout: NSTimeInterval) {
        if processable.isRunning {
            let e = expectationWithDescription(String(reflecting: processable))
            processable.subscribeOnce { (event: ProcessableBatchDidFinish, emitter) in
                e.fulfill()
            }
            waitForExpectationsWithTimeout(timeout, handler: nil)
        }
    }

    func resolvePath(path: RelPath) -> NSURL {
        return path.resolve(baseURL: project.rootURL)
    }

    func updateFile(path: RelPath, block: (String) -> String) {
        let url = resolvePath(path)
        let oldText = try! String(contentsOfURL: url, encoding: NSUTF8StringEncoding)
        let newText = block(oldText)
        try! newText.writeToURL(url, atomically: true, encoding: NSUTF8StringEncoding)
    }

    func readFile(path: RelPath) -> String {
        let url = resolvePath(path)
        return (try? String(contentsOfURL: url, encoding: NSUTF8StringEncoding)) ?? ""
    }

}
