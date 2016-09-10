import XCTest
@testable import ExpressiveCollections

class ExpressiveCollectionsTests: XCTestCase {
    
    func testFind() {
        XCTAssertEqual([1,2,3,4].find { $0 % 2 == 0 }, 2)
    }

    func testArrayAppendOperator() {
        var array = [1, 2, 3]
        array <<< 42
    }

    func testDictionaryAppendOperator() {
        var dict = ["Foo": 1]
        dict += ["Bar": 2]
    }

    func testSubstitution() {
        let values = ["<foo>": "bar", "<boz>": "fu"]
        XCTAssertEqual("foofoofoo".substituteValues(values), "foofoofoo")
        XCTAssertEqual("foo<foo>foo".substituteValues(values), "foobarfoo")
        XCTAssertEqual("foo<foo><foo>".substituteValues(values), "foobarbar")
        XCTAssertEqual("<boz><foo><foo>".substituteValues(values), "fubarbar")
        XCTAssertEqual(["foo<foo>", "<foo>"].substituteValues(values), ["foobar", "bar"])
    }

    func testMultivaluedSubstitution() {
        let values = ["<foo>": ["bar"], "<bar>": [], "<boz>": ["fu", "fubar"]]
        XCTAssertEqual("foofoofoo".substituteValues(values), ["foofoofoo"])
        XCTAssertEqual("foo<foo>foo".substituteValues(values), ["foobarfoo"])
        XCTAssertEqual("foo<foo><foo>".substituteValues(values), ["foobarbar"])
        XCTAssertEqual("<foo>".substituteValues(values), ["bar"])
        XCTAssertEqual("<bar>".substituteValues(values), [])
        XCTAssertEqual("<boz>".substituteValues(values), ["fu", "fubar"])
    }

    func testMismatchedMultivaluedSubstitution() {
        let values = ["<foo>": ["bar"], "<bar>": [], "<boz>": ["fu", "fubar"]]
        // may want to fail on this later
        XCTAssertEqual("foo<foo><foo><bar>".substituteValues(values), ["foobarbar<bar>"])
        XCTAssertEqual("foo<foo><foo><boz>".substituteValues(values), ["foobarbar<boz>"])
    }

}
