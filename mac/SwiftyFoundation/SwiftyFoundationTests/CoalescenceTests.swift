import Foundation
import XCTest
import SwiftyFoundation

class CoalescenceTests: XCTestCase {

    func testObservation() {
        let expection = expectationWithDescription("coalescence done")
        var counter = 0

        let coalescence = Coalescence()
        coalescence.perform {
            ++counter
            switch counter {
            case 2:
                coalescence.perform {
                    XCTFail("Shouldn't be called")
                }
            case 3:
                expection.fulfill()
            default:
                XCTFail("Unexpected counter value");
            }
        }
        coalescence.perform {
            XCTFail("Shouldn't be called")
        }

        XCTAssertEqual(counter, 0)
        ++counter

        waitForExpectationsWithTimeout(2.0) { error in
            XCTAssertEqual(counter, 3)
        }
    }

}
