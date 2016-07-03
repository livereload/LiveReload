import Foundation
import XCTest

let fixturesDirectoryURL = NSURL(fileURLWithPath: #file, isDirectory: false).URLByDeletingLastPathComponent!.URLByDeletingLastPathComponent!.URLByAppendingPathComponent("TestFixtures", isDirectory: true)
let testProjectsDirectoryURL = NSURL(fileURLWithPath: #file, isDirectory: false).URLByDeletingLastPathComponent!.URLByDeletingLastPathComponent!.URLByDeletingLastPathComponent!.URLByAppendingPathComponent("mac/LiveReloadTestProjects", isDirectory: true)
