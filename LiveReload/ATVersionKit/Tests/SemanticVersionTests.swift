import Cocoa
import XCTest
import ATVersionKit

class SemanticVersionTests: XCTestCase {

    func testSemanticVersion() {
        let version = LRSemanticVersion(string: "1.2.3")
        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minor, 2)
        XCTAssertEqual(version.patch, 3)
    }

//    func testSemanticVersion2() {
//        let version = try! SemanticVersion(string: "1.2.3")
//        XCTAssertEqual(version.major, 1)
//        XCTAssertEqual(version.minor, 2)
//        XCTAssertEqual(version.patch, 3)
//    }
//
//    func testSemanticVersion3() {
//        let versionType: Version.Type = SemanticVersion.self
//        let version = try! SemanticVersion(string: "1.2.3")
//        XCTAssertEqual(version.major, 1)
//        XCTAssertEqual(version.minor, 2)
//        XCTAssertEqual(version.patch, 3)
//    }

}
