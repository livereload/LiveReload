import Foundation
import XCTest
import SwiftyFoundation

class FuzzyCastOperatorTests: XCTestCase {

    func testNilToString() {
        let input: AnyObject? = nil
        XCTAssert((input~~~ as String?) == nil)
        XCTAssertEqual((input ~|||~ "foo"), "foo")
    }

    func testString() {
        let input: AnyObject? = "abc"
        XCTAssertEqual((input~~~ as String?)!, "abc")
        XCTAssertEqual((input ~|||~ "foo"), "abc")
    }

    func testEmptyString() {
        let input: AnyObject? = ""
        XCTAssert((input~~~ as String?) == nil)
        XCTAssertEqual(("" ~|||~ "foo"), "foo")
    }

    func testNilToBool() {
        XCTAssertEqual((nil ~|||~ true), true)
    }

    func testBool() {
        XCTAssertEqual((false ~|||~ true), false)
    }

    func testInt() {
        XCTAssertEqual((42 ~|||~ 11), 42)
    }

    func testDouble() {
        let input: AnyObject? = 2.5
        XCTAssertEqual((input~~~ as Double?)!, 2.5)
        XCTAssertEqual((input ~|||~ 1.0), 2.5)
    }

    func testArray() {
        let a: AnyObject = [1, 2, 3]
        let r: [Int] = a ~|||~ []
        XCTAssertEqual("\(r)", "[1, 2, 3]")
    }
    
}

class StringValueTests: XCTestCase {

    func testNil() {
        XCTAssert(StringValue(nil) == nil)
    }

    func testString() {
        XCTAssertEqual(StringValue("abc")!, "abc")
    }

    func testBool() {
        // unfortunately, NSNumber does not allow us to differentiate between Bool and Int
        XCTAssertEqual(StringValue(true)!, "1")
    }

    func testInt() {
        XCTAssertEqual(StringValue(42)!, "42")
    }

    func testArray() {
        XCTAssert(StringValue([1, 2, 3]) == nil)
    }

}

class BoolValueTests: XCTestCase {

    func testNil() {
        XCTAssert(BoolValue(nil) == nil)
    }

    func testBool() {
        XCTAssertEqual(BoolValue(true)!, true)
    }

    func testStringYesUpper() {
        XCTAssertEqual(BoolValue("YES")!, true)
    }

    func testStringYesLower() {
        XCTAssertEqual(BoolValue("yes")!, true)
    }

    func testStringOther() {
        XCTAssert(BoolValue("abc") == nil)
    }

    func testInt0() {
        XCTAssertEqual(BoolValue(0)!, false)
    }

    func testInt1() {
        XCTAssertEqual(BoolValue(1)!, true)
    }

    func testIntAny() {
        XCTAssertEqual(BoolValue(42)!, true)
    }

    func testArray() {
        XCTAssert(BoolValue([1, 2, 3]) == nil)
    }
    
}

class NonEmptyStringValueTests: XCTestCase {

    func testNil() {
        XCTAssert(NonEmptyStringValue(nil) == nil)
    }

    func testString() {
        XCTAssertEqual(NonEmptyStringValue("abc")!, "abc")
    }

    func testEmptyString() {
        XCTAssert(NonEmptyStringValue("") == nil)
    }

    func testBlankString() {
        XCTAssert(NonEmptyStringValue("   ") == nil)
    }

    func testBool() {
        // unfortunately, NSNumber does not allow us to differentiate between Bool and Int
        XCTAssertEqual(NonEmptyStringValue(true)!, "1")
    }

    func testInt() {
        XCTAssertEqual(NonEmptyStringValue(42)!, "42")
    }

    func testArray() {
        XCTAssert(NonEmptyStringValue([1, 2, 3]) == nil)
    }
    
}
