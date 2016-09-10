import XCTest
@testable import ExpressiveCasting

class ExpressiveCastingTests: XCTestCase {

    func testBoolValue() {
        XCTAssertEqual(BoolValue(false), false)
        XCTAssertEqual(BoolValue(true), true)
        XCTAssertEqual(BoolValue(nil), nil)

        XCTAssertEqual(BoolValue(1),       true)
        XCTAssertEqual(BoolValue(123),     true)
        XCTAssertEqual(BoolValue("1"),     true)
        XCTAssertEqual(BoolValue("true"),  true)
        XCTAssertEqual(BoolValue("yes"),   true)
        XCTAssertEqual(BoolValue("y"),     true)
        XCTAssertEqual(BoolValue("on"),    true)
        XCTAssertEqual(BoolValue(NSNumber(int: 1)), true)

        XCTAssertEqual(BoolValue(0),       false)
        XCTAssertEqual(BoolValue("0"),     false)
        XCTAssertEqual(BoolValue("false"), false)
        XCTAssertEqual(BoolValue("no"),    false)
        XCTAssertEqual(BoolValue("n"),     false)
        XCTAssertEqual(BoolValue("off"),   false)
        XCTAssertEqual(BoolValue(NSNumber(int: 0)), false)

        XCTAssertEqual(BoolValue(""),      nil)
        XCTAssertEqual(BoolValue("2"),     nil)
        XCTAssertEqual(BoolValue("x"),     nil)
    }

    func testImplicitConv() {
        let x: AnyObject? = "1"
        let y: Int? = x~~~
        let z = x~~~ ?? 2
        XCTAssertEqual(y, 1)
        XCTAssertEqual(z, 1)
    }

}
