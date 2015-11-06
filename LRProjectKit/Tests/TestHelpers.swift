import Foundation
import XCTest

let fixturesDirectoryURL = NSURL(fileURLWithPath: __FILE__, isDirectory: false).URLByDeletingLastPathComponent!.URLByDeletingLastPathComponent!.URLByAppendingPathComponent("TestFixtures", isDirectory: true)
