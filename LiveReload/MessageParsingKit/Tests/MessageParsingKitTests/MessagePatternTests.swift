import XCTest
@testable import MessageParsingKit

class MessagePatternTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testRegexpAssumptions() {
        let pp = try! NSRegularExpression(pattern: "(\\S[^\\n]+?)", options: [])
        let fm = pp.firstMatchInString("Hello, world", options: [], range: NSMakeRange(0, ("Hello, world" as NSString).length))
        XCTAssertNotNil(fm)
    }

    func testSimplePattern() {
        let p = try! MessagePattern("((message))\n", severity: .Error)
        XCTAssertEqual(p.processedPatternString, "(\\S[^\\n]+?)\n")
        
        do {
            let (rem, msgs) = p.parse("Hello, world")
            XCTAssertEqual(msgs.count, 1)
            XCTAssertEqual(msgs[0].text, "Hello, world")
            XCTAssertEqual(rem, "")
        }
        
        do {
            let (rem, msgs) = p.parse("Hello\nthere\n")
            XCTAssertEqual(msgs.count, 2)
            XCTAssertEqual(msgs[0].text, "Hello")
            XCTAssertEqual(msgs[1].text, "there")
            XCTAssertEqual(rem, "")
        }
    }
    
    func testTrivialPattern() {
        let p = try! MessagePattern("hello world", severity: .Error)
        
        do {
            let (rem, msgs) = p.parse("hello there")
            XCTAssertEqual(msgs.count, 0)
            XCTAssertEqual(rem, "hello there")
        }
        
        do {
            let (rem, msgs) = p.parse("say 'hello world'")
            XCTAssertEqual(msgs.count, 1)
            XCTAssertEqual(rem, "say ''")
        }
    }
    
    func testPrefixedPattern() {
        let p = try! MessagePattern("error: ((message))\n", severity: .Error)
        
        do {
            let (rem, msgs) = p.parse("error: hello world")
            XCTAssertEqual(msgs.count, 1)
            XCTAssertEqual(msgs[0].text, "hello world")
            XCTAssertEqual(rem, "")
        }
    }
    
    func testCustomizedPattern() {
        let p = try! MessagePattern("((message:error: [^:]*))", severity: .Error)
        
        do {
            let (rem, msgs) = p.parse("error: hello world: foo bar")
            XCTAssertEqual(msgs.count, 1)
            XCTAssertEqual(msgs[0].text, "error: hello world")
            XCTAssertEqual(rem, ": foo bar")
        }
    }
    
    func testMultiplePatterns() {
        let p = try! MessagePattern("((file)):((line)) ((message))\n", severity: .Error)
        
        do {
            let (rem, msgs) = p.parse("foo.c:12 syntax error")
            XCTAssertEqual(msgs.count, 1)
            XCTAssertEqual(msgs[0].text, "syntax error")
            XCTAssertEqual(msgs[0].file, "foo.c")
            XCTAssertEqual(msgs[0].line, 12)
            XCTAssertEqual(rem, "")
        }
    }
    
    func testMessageOverride() {
        let p = try! MessagePattern("TypeError: ((message))\n", severity: .Error, messageOverride: "Internal compiler error: ***")
        
        do {
            let (rem, msgs) = p.parse("TypeError: foo.bar is not an object")
            XCTAssertEqual(msgs.count, 1)
            XCTAssertEqual(msgs[0].text, "Internal compiler error: foo.bar is not an object")
            XCTAssertEqual(rem, "")
        }
    }
    
    func testEscapeMatching() {
        let p = try! MessagePattern("<ESC>((message))<ESC> in <ESC>((file))<ESC> on line ((line)), column ((column))", severity: .Error)
        
        do {
            let (_, msgs) = p.parse("\u{1b}[31mSyntaxError: expected ')' got '='\u{1b}[39m\u{1b}[31m in \u{1b}[39m/foo/bar/boz.less\u{1b}[90m on line 5, column 6:\u{1b}[39m\u{1b}[90m4 \u{1b}[39m\n5 .b(@v\u{1b}[7m\u{1b}[31m\u{1b}[1m=\u{1b}[22mnone){\u{1b}[39m\u{1b}[27m")
            XCTAssertEqual(msgs.count, 1)
            XCTAssertEqual(msgs[0].text, "SyntaxError: expected ')' got '='")
            XCTAssertEqual(msgs[0].file, "/foo/bar/boz.less")
            XCTAssertEqual(msgs[0].line, 5)
            XCTAssertEqual(msgs[0].column, 6)
        }
    }

}
