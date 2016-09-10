import XCTest
@testable import ExpressiveFoundation

class SchedulingTests: XCTestCase {
    
    func testDelayed() {
        let e = expectationWithDescription("Delayed")
        let d = Delayed()
        d.performAfterDelay(0.01) {
            e.fulfill()
        }
        waitForExpectationsWithTimeout(0.1, handler: nil)
    }

}
