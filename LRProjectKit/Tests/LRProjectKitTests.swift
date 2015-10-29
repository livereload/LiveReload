import XCTest
@testable import LRProjectKit

class LRProjectKitTests: XCTestCase {

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
    
//    func testExample() {
//        let project = newTestProject(<#T##name: String##String#>)
//    }
//
//    private func newTestProject(name: String) -> Project {
//        
//    }

}
