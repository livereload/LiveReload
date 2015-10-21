import XCTest
@testable import LRProjectKit

class LRProjectKitTests: XCTestCase {

    var ws: Workspace!
    
    override func setUp() {
        super.setUp()
        ws = Workspace()
    }
    
    override func tearDown() {
        ws.dispose()
        super.tearDown()
    }
    
    func testExample() {
    }

}
