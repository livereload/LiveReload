import Foundation
import XCTest
import ATCocoaLabs

class PrecisionReductionTests: XCTestCase {
    
    func test0_1() {
        XCTAssertEqual(ReducedPrecisionRange(value: 0).description, "0", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 1).description, "1", "Pass")
    }

    func test2_9() {
        XCTAssertEqual(ReducedPrecisionRange(value: 2).description, "2-9", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 3).description, "2-9", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 8).description, "2-9", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 9).description, "2-9", "Pass")
    }
    
    func test10_29() {
        XCTAssertEqual(ReducedPrecisionRange(value: 10).description, "10-29", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 11).description, "10-29", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 28).description, "10-29", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 29).description, "10-29", "Pass")
    }
    
    func test30_99() {
        XCTAssertEqual(ReducedPrecisionRange(value: 30).description, "30-99", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 31).description, "30-99", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 98).description, "30-99", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 99).description, "30-99", "Pass")
    }
    
    func test100_999() {
        XCTAssertEqual(ReducedPrecisionRange(value: 100).description, "100-999", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 101).description, "100-999", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 998).description, "100-999", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 999).description, "100-999", "Pass")
    }
    
    func test1000_9999() {
        XCTAssertEqual(ReducedPrecisionRange(value: 1000).description, "1000-9999", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 1001).description, "1000-9999", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 9998).description, "1000-9999", "Pass")
        XCTAssertEqual(ReducedPrecisionRange(value: 9999).description, "1000-9999", "Pass")
    }
    
}
