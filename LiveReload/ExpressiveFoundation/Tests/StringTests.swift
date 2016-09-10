import XCTest
@testable import ExpressiveFoundation

class StringTests: XCTestCase {

    func testSuffix() {
        XCTAssertEqual("foo".removeSuffix("bar").0, "foo")
        XCTAssertEqual("foo".removeSuffix("bar").1, false)

        XCTAssertEqual("foobar".removeSuffix("bar").0, "foo")
        XCTAssertEqual("foobar".removeSuffix("bar").1, true)

        XCTAssertEqual("foo".replaceSuffix("bar", "boz").0, "foo")
        XCTAssertEqual("foobar".replaceSuffix("bar", "boz").0, "fooboz")
    }

}
