import XCTest
@testable import ATPathSpec

class RelPathTests: XCTestCase {

    func testOneFile() {
        let p = RelPath("foo")
        XCTAssertEqual(p.isDirectory, false)
        XCTAssertEqual(p.components.count, 1)
        XCTAssertEqual(p.components[0], "foo")
    }

    func testOneFolder() {
        let p = RelPath("foo/")
        XCTAssertEqual(p.isDirectory, true)
        XCTAssertEqual(p.components.count, 1)
        XCTAssertEqual(p.components[0], "foo")
    }

    func testTwoFile() {
        let p = RelPath("foo/bar")
        XCTAssertEqual(p.isDirectory, false)
        XCTAssertEqual(p.components.count, 2)
        XCTAssertEqual(p.components[0], "foo")
        XCTAssertEqual(p.components[1], "bar")
    }

    func testTwoFolder() {
        let p = RelPath("foo/bar/")
        XCTAssertEqual(p.isDirectory, true)
        XCTAssertEqual(p.components.count, 2)
        XCTAssertEqual(p.components[0], "foo")
        XCTAssertEqual(p.components[1], "bar")
    }

    func testEmpty() {
        let p = RelPath()
        XCTAssertEqual(p.isDirectory, true)
        XCTAssertEqual(p.components.count, 0)
    }

    func testEmptyString() {
        XCTAssertEqual(RelPath(""), RelPath())
    }

    func testLeadingSlash() {
        XCTAssertEqual(RelPath("/"), RelPath())
        XCTAssertEqual(RelPath("/foo"), RelPath("foo"))
        XCTAssertEqual(RelPath("/foo/"), RelPath("foo/"))
        XCTAssertEqual(RelPath("/foo/bar"), RelPath("foo/bar"))
        XCTAssertEqual(RelPath("/foo/bar/"), RelPath("foo/bar/"))
    }

    func testInequality() {
        XCTAssertNotEqual(RelPath("foo"), RelPath())
        XCTAssertNotEqual(RelPath("foo"), RelPath("foo/"))
        XCTAssertNotEqual(RelPath("foo"), RelPath("foo/bar"))
    }

    func testParent() {
        XCTAssertEqual(RelPath().parent, RelPath())
        XCTAssertEqual(RelPath("foo").parent, RelPath())
        XCTAssertEqual(RelPath("foo/bar").parent, RelPath("foo/"))
        XCTAssertEqual(RelPath("foo/bar/boz").parent, RelPath("foo/bar/"))
    }

    func testChild() {
        XCTAssertEqual(RelPath().childNamed("foo", isDirectory: false), RelPath("foo"))
        XCTAssertEqual(RelPath().childNamed("foo", isDirectory: true), RelPath("foo/"))
        XCTAssertEqual(RelPath("foo/").childNamed("bar", isDirectory: true), RelPath("foo/bar/"))
        XCTAssertEqual(RelPath("foo/").childNamed("bar", isDirectory: false), RelPath("foo/bar"))
    }

    func testPathExtension() {
        XCTAssertEqual(RelPath().hasPathExtension("txt"), false)
        XCTAssertEqual(RelPath("foo").hasPathExtension("txt"), false)
        XCTAssertEqual(RelPath("foo.txt").hasPathExtension("txt"), true)

        XCTAssertEqual(RelPath("foo.php.txt").hasPathExtension("txt"), true)
        XCTAssertEqual(RelPath("foo.txt.php").hasPathExtension("txt"), false)
        XCTAssertEqual(RelPath("foo.txt.php").hasPathExtension("txt.php"), true)

        XCTAssertEqual(RelPath("foo").pathExtensionCandidates, [])
        XCTAssertEqual(RelPath("foo.").pathExtensionCandidates, [""])
        XCTAssertEqual(RelPath("foo.txt").pathExtensionCandidates, ["txt"])
        XCTAssertEqual(RelPath("foo.txt.php").pathExtensionCandidates, ["php", "txt.php"])
    }

}
