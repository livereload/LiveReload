import XCTest
@testable import LRProjectKit

class LRProjectKitTests: ProjectTestCase {


    override func setUp() {
        super.setUp()
        setupPlugins()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExample() {
        runSelfTest(.Integration, "compilers/less_imports")
    }

}
