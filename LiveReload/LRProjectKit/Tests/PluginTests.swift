import XCTest
import ExpressiveFoundation
@testable import LRProjectKit
import Uniflow

class PluginTests: XCTestCase {

    var bus: Bus!
    var ws: Workspace!

    override func setUp() {
        super.setUp()
        bus = Bus()
        ws = Workspace(bus: bus)
    }

    override func tearDown() {
        ws.dispose()
        super.tearDown()
    }

    func testSimplePlugin() {
        let e = expectationWithDescription("ProcessableBatchDidFinish")
        let plugin = Plugin(folderURL: fixturesDirectoryURL.URLByAppendingPathComponent("Plugins/Foo.lrplugin", isDirectory: true), context: ws)
        var o = Observation()
        o += plugin.subscribe { (event: ProcessableBatchDidFinish, sender) in
            e.fulfill()
        }
        plugin.update(.Initial)

        waitForExpectationsWithTimeout(1) { error in
            o.unobserve()
            defer { plugin.dispose() }
            guard error == nil else { return }

            XCTAssertEqual(String(plugin.log), "(empty)")

            XCTAssertEqual(plugin.actions.count, 1)
            guard plugin.actions.count >= 1 else { return }
            XCTAssertEqual(plugin.actions[0].name, "FOO")
            XCTAssertEqual(plugin.actions[0].identifier, "foo")
        }
    }

    func testPluginManager() {
        let e = expectationWithDescription("ProcessableBatchDidFinish")

        let manager = PluginManager(context: ws)
        manager.pluginContainerURLs = [fixturesDirectoryURL.URLByAppendingPathComponent("Plugins", isDirectory: true)]

        var o = Observation()
        o += manager.subscribe { (event: ProcessableBatchDidFinish, sender) in
            e.fulfill()
        }
        manager.update(.Initial)

        waitForExpectationsWithTimeout(1) { error in
            o.unobserve()
            defer { manager.dispose() }
            guard error == nil else { return }

            XCTAssertEqual(manager.plugins.count, 1)
            guard manager.plugins.count >= 1 else { return }
            XCTAssertEqual(manager.plugins[0].name, "Foo")
            XCTAssertEqual(manager.plugins[0].actions.count, 1)
        }
    }

}
