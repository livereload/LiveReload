import Cocoa
import XCTest
import SwiftyFoundation
import Swift  // for IDE navigation

let digitsArray = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

class AlgorithmTests: XCTestCase {

    func testFindIf() {
        let v = findIf(digitsArray) { ($0 > 3) && ($0 % 2 == 0) }
        XCTAssertEqual(v!, 4, "Pass")
    }

    func testFindMapped() {
        let v = findMapped(digitsArray) { ($0 > 3) && ($0 % 2 == 0) ? $0*$0 : nil }
        XCTAssertEqual(v!, 16, "Pass")
    }

    func testMapIf() {
        let output = mapIf(digitsArray) { ($0 % 2 == 0) ? $0*$0 : nil }
        XCTAssertEqual("\(output)", "[0, 4, 16, 36, 64]", "Pass")
    }

    func testAll() {
        XCTAssertEqual(all(digitsArray) { $0 < 10 }, true, "Pass")
        XCTAssertEqual(all(digitsArray) { $0 < 9 }, false, "Pass")
    }

    func testStdlibContains() {
        XCTAssertEqual(contains(digitsArray) { $0 < 10 }, true, "Pass")
        XCTAssertEqual(contains(digitsArray) { $0 < 9 }, true, "Pass")
        XCTAssertEqual(contains(digitsArray) { $0 > 9 }, false, "Pass")
    }

    func testFlatten() {
        let output = flatten([[1, 2], [3], [], [4, 5]])
        XCTAssertEqual("\(output)", "[1, 2, 3, 4, 5]", "Pass")
    }

    func testRemoveElement() {
        var array = digitsArray
        removeElement(&array, 7)
        XCTAssertEqual("\(array)", "[0, 1, 2, 3, 4, 5, 6, 8, 9]", "Pass")
    }

    func testRemoveElementsByArray() {
        var array = digitsArray
        removeElements(&array, [7, 3])
        XCTAssertEqual("\(array)", "[0, 1, 2, 4, 5, 6, 8, 9]", "Pass")
    }

    func testRemoveElementsBySequence() {
        var array = digitsArray
        removeElements(&array, 3...6)
        XCTAssertEqual("\(array)", "[0, 1, 2, 7, 8, 9]", "Pass")
    }

    func testRemoveElementsByPredicate() {
        var array = digitsArray
        removeElements(&array) { $0 % 3 == 0 }
        XCTAssertEqual("\(array)", "[1, 2, 4, 5, 7, 8]", "Pass")
    }

//    func testArrayFindIf() {
//        let v = digitsArray.find { ($0 > 3) && ($0 % 2 == 0) }
//        XCTAssertEqual(v!, 4, "Pass")
//    }

}
