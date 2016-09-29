import XCTest
@testable import MessageParsingKit

class MessagePatternTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSimplePattern() {
        let pp = try! NSRegularExpression(pattern: "(\\S[^\\n]+?)", options: [])
        let fm = pp.firstMatchInString("Hello, world", options: [], range: NSMakeRange(0, ("Hello, world" as NSString).length))
        XCTAssertNotNil(fm)
        
        let p = try! MessagePattern("((message))$")
        XCTAssertEqual(p.processedPatternString, "(\\S[^\\n]+?)$")
        
        let (rem, msgs) = p.parse("Hello, world")
        XCTAssertEqual(msgs.count, 1)
        XCTAssertEqual(msgs[0].text, "Hello, world")
        XCTAssertEqual(rem, "")
    }

}
