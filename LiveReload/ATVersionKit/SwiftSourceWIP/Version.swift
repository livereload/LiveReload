import Foundation

public protocol Version: Comparable, String {

//    var versionSpace: VersionSpace<Self> { get }

    init(string: String) throws

    var major: Int { get }
    var minor: Int { get }

}

//public extension Version where Self: Comparable {
//
//    func isLess(thanVersion version: Version) -> Bool? {
//    }
//
//}

//public class VersionSpace<V: Version> {
//
//    func versionWithString(string: String) throws -> V {
//        fatalError()
//    }
//
//    func versionWithComponents(major: Int, minor: Int) -> V {
//        fatalError()
//    }
//
//}
