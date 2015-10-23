import XCTest
import ExpressiveFoundation
@testable import LRProjectKit

class PluginTests: XCTestCase {

    var ws: Workspace!

    let fixturesDirectoryURL = NSURL(fileURLWithPath: __FILE__, isDirectory: false).URLByDeletingLastPathComponent!.URLByDeletingLastPathComponent!.URLByAppendingPathComponent("TestFixtures", isDirectory: true)

    override func setUp() {
        super.setUp()
        ws = Workspace()
    }

    override func tearDown() {
        ws.dispose()
        super.tearDown()
    }

    func testSimplePlugin() {
        let e = expectationWithDescription("UpdateBatchDidFinish")
        let plugin = Plugin(folderURL: fixturesDirectoryURL.URLByAppendingPathComponent("Plugins/SimplePlugin.lrplugin", isDirectory: true), context: ws)
        var o = Observation()
        o += plugin.subscribe { (event: UpdatableStateDidChange, sender) in
            if !plugin.isUpdating {
                e.fulfill()
            }
        }
        plugin.update(.Initial)

        waitForExpectationsWithTimeout(0.1) { error in
            o.unobserve()
            if error != nil { return }

            XCTAssertEqual(String(plugin.log), "(empty)")

            XCTAssertEqual(plugin.actions.count, 1)
            if plugin.actions.count < 1 { return }
            XCTAssertEqual(plugin.actions[0].name, "LESS")
            XCTAssertEqual(plugin.actions[0].identifier, "less")
        }
    }

    func testPluginManager() {
        let e = expectationWithDescription("UpdateBatchDidFinish")

        let manager = PluginManager(context: ws)
        manager.pluginContainerURLs = [fixturesDirectoryURL.URLByAppendingPathComponent("Plugins", isDirectory: true)]

        var o = Observation()
        o += manager.subscribe { (event: UpdatableStateDidChange, sender) in
            if !manager.isUpdating {
                e.fulfill()
            }
        }
        manager.update(.Initial)

        waitForExpectationsWithTimeout(0.1) { error in
            o.unobserve()
            if error != nil { return }

            XCTAssertEqual(manager.plugins.count, 1)
            if manager.plugins.count < 1 { return }
            XCTAssertEqual(manager.plugins[0].name, "SimplePlugin")
            XCTAssertEqual(manager.plugins[0].actions.count, 1)
        }
    }

}
